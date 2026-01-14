# Load Balancer Module - Outputs

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer (for CloudWatch)"
  value       = aws_lb.main.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer (for Route53)"
  value       = aws_lb.main.zone_id
}

output "target_group_id" {
  description = "ID of the target group"
  value       = aws_lb_target_group.app.id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app.arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group (for CloudWatch)"
  value       = aws_lb_target_group.app.arn_suffix
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (if enabled)"
  value       = var.enable_https ? aws_lb_listener.https[0].arn : null
}

output "load_balancer_url" {
  description = "URL to access the load balancer"
  value       = var.enable_https ? "https://${aws_lb.main.dns_name}" : "http://${aws_lb.main.dns_name}"
}

output "load_balancer_summary" {
  description = "Summary of load balancer configuration"
  value = {
    alb_dns_name      = aws_lb.main.dns_name
    target_group_arn  = aws_lb_target_group.app.arn
    health_check_path = var.health_check_path
    https_enabled     = var.enable_https
    stickiness_enabled = var.enable_stickiness
  }
}
