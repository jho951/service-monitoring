# Monitoring-server 구조와 운영

## 개요

Monitoring-server는 Spring Boot 애플리케이션 서버가 아니라 MSA 서비스들의 메트릭을 수집하고 시각화하는 Docker 기반 모니터링 스택입니다.

구성 요소는 다음과 같습니다.

- Prometheus: 각 서비스의 `/actuator/prometheus` 또는 exporter `/metrics` endpoint를 scrape합니다.
- Grafana: Prometheus를 datasource로 사용해 대시보드를 제공합니다.
- Loki: 서비스 로그를 저장하고 LogQL 조회 API를 제공합니다.
- Promtail: Docker container stdout/stderr 로그를 수집해 Loki로 전송합니다.

## 디렉터리 구조

```text
Monitoring-server/
├── README.md
├── docker/
│   ├── dev/
│   │   └── compose.yml
│   ├── prod/
│   │   └── compose.yml
│   ├── prometheus/
│   │   └── Dockerfile
│   ├── grafana/
│   │   └── Dockerfile
│   ├── loki/
│   │   └── Dockerfile
│   └── promtail/
│       └── Dockerfile
├── docs/
│   ├── README.md
│   └── monitoring-server.md
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml
│   ├── loki/
│   │   └── loki-config.yml
│   ├── promtail/
│   │   └── promtail-config.yml
│   └── grafana/
│       ├── dashboards/
│       │   └── spring-boot-overview.json
│       └── provisioning/
│           ├── dashboards/
│           │   └── dashboards.yml
│           └── datasources/
│               └── prometheus.yml
└── scripts/
    └── run.docker.sh
```

## 실행 방법

```bash
./scripts/run.docker.sh up dev
```

종료할 때는 다음 명령을 사용합니다.

```bash
./scripts/run.docker.sh down dev
```

운영형 compose는 다음과 같이 실행합니다.

```bash
./scripts/run.docker.sh up prod
```

접속 주소는 다음과 같습니다.

- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3005`
- Loki: `http://localhost:3100`

Grafana 기본 계정은 다음과 같습니다.

- ID: `admin`
- PW: `admin`

운영 환경에서는 `GRAFANA_ADMIN_USER`, `GRAFANA_ADMIN_PASSWORD` 환경 변수로 기본 계정을 변경해야 합니다.

## Docker Compose 구성

이 프로젝트는 환경별로 compose를 분리합니다.

- `docker/dev/compose.yml`: 로컬 개발용. 공식 이미지를 사용하고 설정 파일을 bind mount합니다.
- `docker/prod/compose.yml`: 운영 배포용. repo 내부 `Dockerfile`로 이미지를 빌드하고, CI/CD에서는 GHCR 이미지 참조를 주입해 배포합니다.

운영 배포 시 compose가 받는 주요 이미지 변수는 다음과 같습니다.

- `PROMETHEUS_IMAGE`
- `GRAFANA_IMAGE`
- `LOKI_IMAGE`
- `PROMTAIL_IMAGE`

CD workflow는 위 4개 변수를 `${GITHUB_SHA}` 태그 GHCR 이미지로 export한 뒤 `DEPLOY_COMMAND`를 실행합니다.

### Prometheus

- 이미지: `prom/prometheus:v2.54.1`
- 컨테이너 이름: `monitoring-prometheus`
- 기본 포트: `9090`
- 설정 파일 mount:
  - host: `monitoring/prometheus/prometheus.yml`
  - container: `/etc/prometheus/prometheus.yml`
- 데이터 volume: `prometheus-data`
- 네트워크:
  - `service-backbone-shared`
  - `monitoring-private`

### Grafana

- 이미지: `grafana/grafana:11.2.2`
- 컨테이너 이름: `monitoring-grafana`
- 기본 포트: `3005`
- 데이터 volume: `grafana-data`
- provisioning mount:
  - `monitoring/grafana/provisioning`
- dashboard mount:
  - `monitoring/grafana/dashboards` -> `/etc/grafana/dashboards`
- 네트워크:
  - `monitoring-private`

Grafana는 Prometheus와 같은 private network에만 붙어 있고, 애플리케이션 서비스 네트워크에는 직접 붙지 않습니다. 서비스 메트릭 수집은 Prometheus가 담당합니다.

### Loki

- 이미지: `grafana/loki:3.2.1`
- 컨테이너 이름: `monitoring-loki`
- 기본 포트: `3100`
- 설정 파일 mount:
  - host: `monitoring/loki/loki-config.yml`
  - container: `/etc/loki/loki-config.yml`
- 데이터 volume: `loki-data`
- 네트워크:
  - `monitoring-private`

### Promtail

- 이미지: `grafana/promtail:3.2.1`
- 컨테이너 이름: `monitoring-promtail`
- 설정 파일 mount:
  - host: `monitoring/promtail/promtail-config.yml`
  - container: `/etc/promtail/promtail-config.yml`
- Docker log 수집 mount:
  - `/var/run/docker.sock`
- position volume: `promtail-positions`
- 네트워크:
  - `monitoring-private`

## 네트워크 구조

`scripts/run.docker.sh`는 `up` 실행 시 `SERVICE_SHARED_NETWORK` 값을 확인합니다.

기본값은 다음과 같습니다.

```text
service-backbone-shared
```

해당 Docker network가 없으면 스크립트가 자동 생성합니다.

Prometheus는 이 external network에 붙어서 다른 서비스 컨테이너 이름을 DNS로 조회합니다. 따라서 모니터링 대상 서비스들도 동일한 `service-backbone-shared` 네트워크에 연결되어 있어야 합니다.

## Prometheus scrape 대상

Prometheus 설정 파일은 `monitoring/prometheus/prometheus.yml`입니다.

현재 활성 scrape 대상은 다음과 같습니다.

| Job | Target | Metrics path | Label |
| --- | --- | --- | --- |
| `prometheus` | `localhost:9090` | 기본값 | 없음 |
| `auth-service` | `auth-service:8081` | `/actuator/prometheus` | `service=auth-service` |
| `user-service` | `user-service:8082` | `/actuator/prometheus` | `service=user-service` |
| `authz-service` | `permission-service:8084` | `/actuator/prometheus` | `service=authz-service` |
| `api-gateway-server` | `gateway:8080` | `/actuator/prometheus` | `service=api-gateway-server` |
| `editor-service` | `editor-service:8083` | `/actuator/prometheus` | `service=editor-service` |
| `redis-server` | `central-redis-exporter:9121` | `/metrics` | `service=redis-server` |

`editor-service`는 현재 `editor-service:8083` target으로 조회됩니다.

## Spring Boot 서비스 연동 기준

모니터링 대상 Spring Boot 서비스는 최소한 다음 endpoint를 노출해야 합니다.

```text
/actuator/health
/actuator/prometheus
```

Gradle dependency 예시는 다음과 같습니다.

```gradle
implementation 'org.springframework.boot:spring-boot-starter-actuator'
runtimeOnly 'io.micrometer:micrometer-registry-prometheus'
```

공통 설정 예시는 다음과 같습니다.

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      probes:
        enabled: true
      show-details: never
  metrics:
    tags:
      service: ${spring.application.name}
      env: ${SPRING_PROFILES_ACTIVE:local}
```

서비스별 `spring.application.name`과 Prometheus job label의 `service` 값은 가능하면 동일하게 맞추는 것이 좋습니다. 그래야 Grafana 쿼리에서 서비스별 집계가 일관됩니다.

## 로그 수집

Promtail은 Docker socket을 통해 실행 중인 container를 발견하고 stdout/stderr 로그를 Loki로 전송합니다.

Grafana Explore에서 datasource를 `Loki`로 선택한 뒤 LogQL로 조회합니다.

```logql
{service="auth-service"}
```

Promtail은 Docker Compose service 이름을 `service` label로 사용합니다. 따라서 각 애플리케이션 compose service 이름을 `auth-service`, `user-service`, `gateway`처럼 일관되게 유지하는 것이 좋습니다.

Spring Boot 서비스는 파일 로그보다 stdout 로그를 우선 사용합니다. Auth-server는 MDC가 포함된 `key=value` 로그를 출력하며, 공통 필드는 `request_id`, `correlation_id`, `trace_id`, `service`, `method`, `uri`, `client_ip`입니다. 요청 완료 로그는 `event=http_request_completed status=... elapsed_ms=...` 형태로 남깁니다.

## Redis metric

Redis metric은 Redis 서버 자체가 아니라 exporter를 통해 수집합니다.

현재 Prometheus target은 다음입니다.

```text
central-redis-exporter:9121
```

Redis exporter는 `redis-server`의 monitoring profile이 필요합니다.

```bash
cd ../redis-server
./scripts/run.docker.sh up-monitoring
```

## Grafana provisioning

Grafana datasource 설정은 `monitoring/grafana/provisioning/datasources/prometheus.yml`입니다.

주요 설정은 다음과 같습니다.

```yaml
name: Prometheus
uid: prometheus
type: prometheus
url: http://prometheus:9090
isDefault: true
```

Loki datasource도 같은 파일에서 자동 등록됩니다.

```yaml
name: Loki
uid: loki
type: loki
url: http://loki:3100
```

Dashboard provider 설정은 `monitoring/grafana/provisioning/dashboards/dashboards.yml`입니다.

Dashboard JSON 파일은 컨테이너 내부의 `/etc/grafana/dashboards`에 배치되고, Grafana의 `MSA` folder 아래에 로드됩니다.

## 기본 대시보드

현재 기본 대시보드는 `monitoring/grafana/dashboards/spring-boot-overview.json`입니다.

대시보드 이름은 `Spring Boot Overview`이며, 주요 패널은 다음과 같습니다.

| Panel | PromQL |
| --- | --- |
| HTTP Request Rate | `sum by (service) (rate(http_server_requests_seconds_count[5m]))` |
| HTTP 5xx Ratio | `sum by (service) (rate(http_server_requests_seconds_count{status=~"5.."}[5m])) / sum by (service) (rate(http_server_requests_seconds_count[5m]))` |
| HTTP Max Latency | `max by (service) (http_server_requests_seconds_max)` |
| JVM Memory Used | `sum by (service) (jvm_memory_used_bytes)` |

이 대시보드는 Spring Boot Actuator와 Micrometer Prometheus registry가 노출하는 기본 metric 이름을 기준으로 작성되어 있습니다.

## 상태 확인

Docker daemon이 실행 중일 때 다음 명령으로 컨테이너 상태를 확인할 수 있습니다.

개발 환경:

```bash
docker compose -p monitoring-server -f docker/dev/compose.yml ps
```

운영 환경:

```bash
docker compose -p monitoring-server -f docker/prod/compose.yml ps
```

Prometheus target 상태는 브라우저에서 다음 페이지로 확인합니다.

```text
http://localhost:9090/targets
```

대상 서비스가 `DOWN`으로 표시되면 다음을 우선 확인합니다.

- 대상 서비스 컨테이너가 실행 중인지 확인합니다.
- 대상 서비스가 `service-backbone-shared` 네트워크에 붙어 있는지 확인합니다.
- Prometheus target 이름과 실제 Docker service/container 이름이 일치하는지 확인합니다.
- 대상 서비스가 `/actuator/prometheus`를 노출하는지 확인합니다.
- Spring Security가 actuator endpoint 접근을 막고 있지 않은지 확인합니다.
