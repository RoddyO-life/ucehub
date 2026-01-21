variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for monitoring instances"
  type        = string
}

variable "prometheus_instance_type" {
  description = "Prometheus instance type"
  type        = string
  default     = "t3.small"
}

variable "grafana_instance_type" {
  description = "Grafana instance type"
  type        = string
  default     = "t3.small"
}

variable "prometheus_security_group_id" {
  description = "Prometheus security group ID"
  type        = string
}

variable "grafana_security_group_id" {
  description = "Grafana security group ID"
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB listener ARN"
  type        = string
}

variable "alb_dns" {
  description = "ALB DNS name"
  type        = string
}

variable "nat_gateway_id" {
  description = "NAT Gateway ID"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
