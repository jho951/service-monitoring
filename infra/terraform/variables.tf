variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name used in tags."
  type        = string
  default     = "msa"
}

variable "environment" {
  description = "Environment name used in resource names."
  type        = string
  default     = "prod"
}

variable "service_name" {
  description = "Logical service name from service-contract."
  type        = string
  default     = "monitoring-service"
}

variable "service_runtime_name" {
  description = "Runtime stack name."
  type        = string
  default     = "monitoring-server"
}

variable "tags" {
  description = "Additional tags to apply to all taggable resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the monitoring VPC."
  type        = string
  default     = "10.26.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs."
  type        = list(string)
  default     = ["10.26.1.0/24", "10.26.2.0/24"]
}

variable "ingress_cidrs" {
  description = "CIDRs allowed to reach Grafana/Prometheus/Loki directly."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_ingress_cidrs" {
  description = "CIDRs allowed to SSH into EC2. Leave empty and use SSM Session Manager where possible."
  type        = list(string)
  default     = []
}

variable "ec2_key_name" {
  description = "Optional existing EC2 key pair name for SSH access."
  type        = string
  default     = ""
}

variable "ec2_ami_id" {
  description = "Optional AMI override. When empty, the latest Amazon Linux 2023 x86_64 AMI is used."
  type        = string
  default     = ""
}

variable "ec2_instance_type" {
  description = "EC2 instance type for monitoring."
  type        = string
  default     = "t3.small"
}

variable "ec2_root_volume_size" {
  description = "EC2 root volume size in GiB."
  type        = number
  default     = 40
}

variable "prometheus_port" {
  description = "Prometheus host port."
  type        = number
  default     = 9090
}

variable "grafana_port" {
  description = "Grafana host port."
  type        = number
  default     = 3005
}

variable "loki_port" {
  description = "Loki host port."
  type        = number
  default     = 3100
}

variable "grafana_admin_user" {
  description = "Grafana admin username."
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password."
  type        = string
  sensitive   = true
}

variable "docker_compose_version" {
  description = "Docker Compose plugin version installed by user data when it is missing."
  type        = string
  default     = "2.29.7"
}
