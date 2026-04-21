# monitor-server Terraform

This stack follows the MSA Terraform contract from `service-contract/contracts/common/terraform.md`.

Unlike the application services, Monitoring-server does not build one service image. Terraform provisions an EC2 host and bootstraps the observability compose stack:

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
- Prometheus scrape targets must be reachable from the monitoring EC2 host. In a full MSA AWS layout, connect service VPCs through the shared network design before relying on these defaults.
- Grafana admin password is stored in Terraform state. Use an encrypted remote backend before sharing this state or using it for production.
