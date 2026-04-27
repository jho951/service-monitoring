# Troubleshooting

## Prometheus target이 DOWN 상태다

증상:

- Grafana dashboard가 비어 있다
- Prometheus target page에서 서비스가 DOWN 으로 보인다

점검:

1. 대상 서비스가 `/actuator/health`, `/actuator/prometheus`를 노출하는지 확인합니다.
2. Docker compose service 이름과 Prometheus scrape target host 이름이 맞는지 확인합니다.
3. monitoring stack과 대상 서비스가 같은 Docker network에서 통신 가능한지 확인합니다.
4. 대상 서비스의 actuator exposure 설정에 `prometheus`가 포함되는지 확인합니다.

## Grafana에는 접속되는데 dashboard나 datasource가 비어 있다

점검:

1. Grafana provisioning 파일이 컨테이너에 mount 되었는지 확인합니다.
2. dev compose 기준 datasource provisioning 경로가 깨지지 않았는지 확인합니다.
3. 기본 계정 `admin/admin`으로 로그인 후 datasource health check가 통과하는지 확인합니다.

## Loki에는 붙었는데 로그가 안 보인다

증상:

- Grafana Explore에서 결과가 없다

점검:

1. Promtail이 Docker socket을 읽을 수 있는지 확인합니다.
2. 조회 label이 compose service 이름과 같은지 확인합니다. 예: `{service="auth-service"}`
3. 컨테이너가 stdout/stderr로 로그를 출력하는지 확인합니다.
4. Promtail과 Loki 간 네트워크 연결이 정상인지 확인합니다.

## Redis metric이 보이지 않는다

해석:

- Redis metric은 `redis-service` exporter target이 살아 있어야 수집됩니다.

점검:

1. `redis-service`에서 `./scripts/run.docker.sh up-monitoring`이 실행 중인지 확인합니다.
2. exporter endpoint가 `9121` 포트에서 열려 있는지 확인합니다.
3. monitoring-service Prometheus target에 exporter host가 올바르게 등록되었는지 확인합니다.

## 특정 서비스만 metric이 없다

점검:

1. 해당 서비스 compose service 이름이 monitoring 설정과 같은지 확인합니다.
2. 서비스가 다른 Docker host나 분리된 VPC에 있어 기존 dev target으로는 수집할 수 없는 구조인지 확인합니다.
3. application metric과 custom metric 경로를 혼동하지 않았는지 확인합니다.

## 운영형 compose가 기동되지 않는다

점검:

1. `PROMETHEUS_IMAGE`, `GRAFANA_IMAGE`, `LOKI_IMAGE`, `PROMTAIL_IMAGE`가 모두 주입되었는지 확인합니다.
2. ECR 또는 registry pull 권한이 있는지 확인합니다.
3. prod compose가 참조하는 env 값과 image tag가 실제 배포 자산과 일치하는지 확인합니다.
