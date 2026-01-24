output "monitoring_instance_id" {
  description = "Monitoring instance ID (from ASG)"
  value       = aws_autoscaling_group.monitoring.id
}

output "monitoring_asg_name" {
  description = "Monitoring Auto Scaling Group name"
  value       = aws_autoscaling_group.monitoring.name
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
