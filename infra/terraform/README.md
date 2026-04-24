# monitoring-service Terraform

This stack follows the MSA Terraform contract from `service-contract/contracts/common/terraform.md`.

Unlike the application services, monitoring-service does not build one service image. Terraform provisions an EC2 host and bootstraps the observability compose stack. Terraform의 logical service name은 `monitoring-service`이고 compose/runtime 이름은 `monitoring-server`를 유지합니다:

- Prometheus
- Grafana
- Loki
- Promtail

## Apply

```bash
cp infra/terraform/terraform.tfvars.example infra/terraform/terraform.tfvars
cd infra/terraform
terraform init
terraform plan
terraform apply
```

After apply, use the outputs:

```bash
terraform output grafana_url
terraform output prometheus_url
terraform output loki_url
```

Bootstrap logs are written to `/var/log/monitoring-server-bootstrap.log`.

## Notes

- Direct Grafana/Prometheus/Loki ingress must be restricted to admin/VPN CIDRs.
- Terraform bootstrap writes the checked-in configs under `monitoring/` to the EC2 host, including Prometheus targets, Grafana datasources, dashboard provisioning, Loki, and Promtail config.
- Update `monitoring/prometheus/targets/ec2-services.yml` to real EC2 private DNS/IPs before apply.
- Prometheus scrape targets must be reachable from the monitoring EC2 host. In a full MSA AWS layout, connect service VPCs through the shared network design before relying on these defaults.
- Grafana admin password is stored in Terraform state. Use an encrypted remote backend before sharing this state or using it for production.
