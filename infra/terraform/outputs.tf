output "service_name" {
  description = "Logical service name."
  value       = var.service_name
}

output "monitoring_public_ip" {
  description = "Public IP of the monitoring EC2 instance."
  value       = aws_instance.monitoring.public_ip
}

output "grafana_url" {
  description = "Direct Grafana URL."
  value       = "http://${aws_instance.monitoring.public_ip}:${var.grafana_port}"
}

output "prometheus_url" {
  description = "Direct Prometheus URL."
  value       = "http://${aws_instance.monitoring.public_ip}:${var.prometheus_port}"
}

output "loki_url" {
  description = "Direct Loki URL."
  value       = "http://${aws_instance.monitoring.public_ip}:${var.loki_port}"
}

output "security_group_id" {
  description = "Monitoring EC2 security group."
  value       = aws_security_group.monitoring.id
}
