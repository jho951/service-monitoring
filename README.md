# Monitoring-server

MSA 서비스의 기본 모니터링 스택입니다.

## Contract Source

- 공통 계약 레포: `https://github.com/jho951/service-contract`
- 계약 동기화 기준 파일: [contract.lock.yml](contract.lock.yml)
- 계약 변경 절차: [contract-change-workflow.md](docs/contract-change-workflow.md)
- PR에서는 `.github/workflows/contract-check.yml`이 lock 파일과 계약 영향 변경 여부를 검사합니다.
- 모니터링 target, 운영 포트, 보안 노출 정책 변경 시 contract 레포 변경을 먼저 반영합니다.

## 구성

- Prometheus: 서비스별 `/actuator/prometheus` metric 수집
- Grafana: Prometheus dashboard
- Loki: 서비스 로그 저장
- Promtail: Docker container stdout/stderr 로그 수집

## 실행

```bash
./scripts/run.docker.sh up dev
```

운영형 compose 검증 또는 실행:

```bash
./scripts/run.docker.sh up prod
```

접속:

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000
- Loki: http://localhost:3100

Grafana 기본 계정:

- ID: `admin`
- PW: `admin`

## Docker 구조

- `docker/dev/compose.yml`: 로컬 개발용. 공식 이미지를 사용하고 설정 디렉터리를 bind mount합니다.
- `docker/prod/compose.yml`: 운영 배포용. 각 구성요소를 repo 내부 `Dockerfile`로 빌드하고, CI/CD에서는 GHCR 이미지 참조로 치환해 배포합니다.
- `docker/prometheus/Dockerfile`
- `docker/grafana/Dockerfile`
- `docker/loki/Dockerfile`
- `docker/promtail/Dockerfile`

운영 배포에서 compose가 읽는 이미지 환경 변수:

- `PROMETHEUS_IMAGE`
- `GRAFANA_IMAGE`
- `LOKI_IMAGE`
- `PROMTAIL_IMAGE`

CD workflow는 위 4개 변수를 `${GITHUB_SHA}` 태그 기준 GHCR 이미지로 export한 뒤 `DEPLOY_COMMAND`를 실행합니다.

## 서비스 적용 기준

각 Spring Boot 서비스는 아래 endpoint를 노출해야 합니다.

```text
/actuator/health
/actuator/prometheus
```

공통 dependency:

```gradle
implementation 'org.springframework.boot:spring-boot-starter-actuator'
runtimeOnly 'io.micrometer:micrometer-registry-prometheus'
```

공통 설정:

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

## Scrape 대상

현재 기본 활성 대상:

- `auth-service:8081`
- `user-service:8082`
- `permission-service:8084`
- `gateway:8080` (`api-gateway-server`)
- `editor-service:8083`
- `central-redis-exporter:9121`

Redis metric은 `redis-server`의 exporter profile이 필요합니다.

```bash
cd ../redis-server
./scripts/run.docker.sh up-monitoring
```

`editor-service`는 현재 `editor-service:8083` target으로 수집합니다.

## 로그 수집

Promtail은 Docker socket을 통해 실행 중인 container를 발견하고 stdout/stderr 로그를 Loki로 전송합니다.

Grafana Explore에서 datasource를 `Loki`로 선택한 뒤 예를 들어 아래처럼 조회할 수 있습니다.

```logql
{service="auth-service"}
```

Compose service 이름이 `service` label로 들어가므로 각 서비스의 compose service 이름을 `auth-service`, `user-service`, `gateway`처럼 일관되게 유지하는 것이 좋습니다.

Spring Boot 서비스는 stdout에 MDC가 포함된 `key=value` 로그를 출력합니다. 예를 들어 auth-service는 `request_id`, `correlation_id`, `trace_id`, `method`, `uri`, `client_ip`를 공통 MDC로 남기고, 요청 완료 로그는 `event=http_request_completed` 형태로 남깁니다.
