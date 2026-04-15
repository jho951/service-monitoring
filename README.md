# Monitoring-server

MSA 서비스의 기본 모니터링 스택입니다.

## 구성

- Prometheus: 서비스별 `/actuator/prometheus` metric 수집
- Grafana: Prometheus dashboard

## 실행

```bash
./scripts/run.docker.sh up
```

접속:

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000

Grafana 기본 계정:

- ID: `admin`
- PW: `admin`

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
- `gateway:8080`
- `central-redis-exporter:9121`

Redis metric은 `redis-server`의 exporter profile이 필요합니다.

```bash
cd ../redis-server
./scripts/run.docker.sh up-monitoring
```

`documents-service`는 actuator/prometheus 적용 후
`monitoring/prometheus/prometheus.yml`의 주석 처리된 job을 활성화합니다.
