# Security Groups Module - Outputs

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "ID of the EC2 instances security group"
  value       = aws_security_group.ec2_instances.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion host security group (if enabled)"
  value       = var.enable_bastion ? aws_security_group.bastion[0].id : null
}

output "prometheus_security_group_id" {
  description = "ID of the Prometheus security group"
  value       = aws_security_group.prometheus.id
}

output "grafana_security_group_id" {
  description = "ID of the Grafana security group"
  value       = aws_security_group.grafana.id
}

output "security_groups_summary" {
  description = "Summary of all security groups created"
  value = {
    alb_sg_id        = aws_security_group.alb.id
    ec2_sg_id        = aws_security_group.ec2_instances.id
    rds_sg_id        = aws_security_group.rds.id
    bastion_sg_id    = var.enable_bastion ? aws_security_group.bastion[0].id : "not_enabled"
    prometheus_sg_id = aws_security_group.prometheus.id
    grafana_sg_id    = aws_security_group.grafana.id
  }
}
