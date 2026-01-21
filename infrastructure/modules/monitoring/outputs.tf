output "prometheus_instance_id" {
  description = "Prometheus instance ID"
  value       = aws_ec2_instance.prometheus.id
}

output "prometheus_private_ip" {
  description = "Prometheus private IP"
  value       = aws_ec2_instance.prometheus.private_ip
}

output "grafana_instance_id" {
  description = "Grafana instance ID"
  value       = aws_ec2_instance.grafana.id
}

output "grafana_private_ip" {
  description = "Grafana private IP"
  value       = aws_ec2_instance.grafana.private_ip
}

output "prometheus_url" {
  description = "Prometheus URL via ALB"
  value       = "http://${var.alb_dns}/prometheus"
}

output "grafana_url" {
  description = "Grafana URL via ALB"
  value       = "http://${var.alb_dns}/grafana"
}

output "grafana_default_password" {
  description = "Grafana default password (change on first login)"
  value       = "admin"
  sensitive   = true
}
