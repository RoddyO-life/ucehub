output "vpc_id" {
  description = "ID de la VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR de la VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs de subnets públicas"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs de subnets privadas (app)"
  value       = module.vpc.private_app_subnet_ids
}

output "private_data_subnet_ids" {
  description = "IDs de subnets privadas (data)"
  value       = module.vpc.private_data_subnet_ids
}

output "nat_instance_id" {
  description = "ID de la NAT Instance"
  value       = module.vpc.nat_instance_id
}

output "nat_instance_ip" {
  description = "IP privada de la NAT Instance"
  value       = module.vpc.nat_instance_private_ip
}

# ========================================
# Resumen de Recursos
# ========================================

output "infrastructure_summary" {
  description = "Resumen de la infraestructura creada"
  value = {
    vpc_id                     = module.vpc.vpc_id
    availability_zones         = var.availability_zones
    public_subnets_count       = length(module.vpc.public_subnet_ids)
    private_app_subnets_count  = length(module.vpc.private_app_subnet_ids)
    private_data_subnets_count = length(module.vpc.private_data_subnet_ids)
    nat_type                   = "NAT Instance (t3.nano)"
    estimated_cost_monthly     = "$3.50 (NAT) + $0 (VPC/Subnets)"
  }
}

# ========================================
# Security Groups Outputs
# ========================================

output "alb_security_group_id" {
  description = "ID del Security Group del ALB"
  value       = module.security_groups.alb_security_group_id
}

output "ec2_security_group_id" {
  description = "ID del Security Group de instancias EC2"
  value       = module.security_groups.ec2_security_group_id
}

output "rds_security_group_id" {
  description = "ID del Security Group de RDS"
  value       = module.security_groups.rds_security_group_id
}

output "security_groups_summary" {
  description = "Resumen de Security Groups"
  value       = module.security_groups.security_groups_summary
}

# ========================================
# Load Balancer Outputs
# ========================================

output "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  value       = module.load_balancer.alb_dns_name
}

output "alb_url" {
  description = "URL para acceder a la aplicación"
  value       = module.load_balancer.load_balancer_url
}

output "target_group_arn" {
  description = "ARN del Target Group"
  value       = module.load_balancer.target_group_arn
}

output "load_balancer_summary" {
  description = "Resumen del Load Balancer"
  value       = module.load_balancer.load_balancer_summary
}

# ========================================
# Compute Outputs
# ========================================

output "autoscaling_group_name" {
  description = "Nombre del Auto Scaling Group"
  value       = module.compute.autoscaling_group_name
}

output "launch_template_id" {
  description = "ID del Launch Template"
  value       = module.compute.launch_template_id
}

output "compute_summary" {
  description = "Resumen de recursos de cómputo"
  value       = module.compute.compute_summary
}

# ========================================
# Complete Infrastructure Summary
# ========================================

output "infrastructure_complete_summary" {
  description = "Resumen completo de toda la infraestructura"
  value = {
    # VPC
    vpc_id             = module.vpc.vpc_id
    availability_zones = var.availability_zones

    # Networking
    public_subnets  = module.vpc.public_subnet_ids
    private_subnets = module.vpc.private_app_subnet_ids
    nat_instance_id = module.vpc.nat_instance_id

    # Security
    alb_sg_id = module.security_groups.alb_security_group_id
    ec2_sg_id = module.security_groups.ec2_security_group_id

    # Load Balancer
    alb_url = module.load_balancer.load_balancer_url

    # Compute
    asg_name      = module.compute.autoscaling_group_name
    instance_type = module.compute.compute_summary.instance_type
    min_instances = module.compute.compute_summary.min_instances
    max_instances = module.compute.compute_summary.max_instances

    # Cost estimate
    estimated_monthly_cost = "$3.50 (NAT) + ~$15-30 (EC2) + ~$16 (ALB) = ~$35-50/month"
  }
}


