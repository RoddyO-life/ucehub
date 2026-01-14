# Compute Module - Outputs

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.app_servers.id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.app_servers.latest_version
}

output "autoscaling_group_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.app_servers.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app_servers.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.app_servers.arn
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile (AWS Academy LabInstanceProfile)"
  value       = data.aws_iam_instance_profile.lab_profile.arn
}

output "key_pair_name" {
  description = "Name of the EC2 key pair (if created)"
  value       = var.create_key_pair ? aws_key_pair.ec2_key[0].key_name : null
}

output "scale_up_policy_arn" {
  description = "ARN of the scale up policy"
  value       = aws_autoscaling_policy.scale_up.arn
}

output "scale_down_policy_arn" {
  description = "ARN of the scale down policy"
  value       = aws_autoscaling_policy.scale_down.arn
}

output "cpu_high_alarm_arn" {
  description = "ARN of the high CPU CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "cpu_low_alarm_arn" {
  description = "ARN of the low CPU CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_low.arn
}

output "ami_id" {
  description = "ID of the AMI used for instances"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "compute_summary" {
  description = "Summary of compute resources"
  value = {
    asg_name          = aws_autoscaling_group.app_servers.name
    instance_type     = var.instance_type
    min_instances     = var.min_instances
    max_instances     = var.max_instances
    desired_instances = var.desired_instances
    ami_id            = data.aws_ami.amazon_linux_2023.id
    docker_image      = var.docker_image
  }
}
