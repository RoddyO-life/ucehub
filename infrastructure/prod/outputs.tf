# UCEHub Production Outputs

output "alb_url" {
  description = "Production Load Balancer URL"
  value       = module.load_balancer.load_balancer_url
}

output "vpc_id" {
  description = "Production VPC ID"
  value       = module.vpc.vpc_id
}

output "infrastructure_summary" {
  description = "Production infrastructure summary"
  value = {
    environment        = var.environment
    vpc_id             = module.vpc.vpc_id
    alb_url            = module.load_balancer.load_balancer_url
    asg_name           = module.compute.autoscaling_group_name
    min_instances      = 2
    max_instances      = 10
    cafeteria_table    = module.dynamodb.cafeteria_orders_table_name
    support_table      = module.dynamodb.support_tickets_table_name
    documents_bucket   = module.s3.documents_bucket_name
  }
}
