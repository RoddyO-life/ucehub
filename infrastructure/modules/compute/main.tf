# Compute Module - EC2 Instances with Docker
# Creates Launch Template, Auto Scaling Group, and EC2 instances

# ============================================================================
# DATA SOURCES
# ============================================================================

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Get existing LabInstanceProfile from AWS Academy
data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}

# ============================================================================
# KEY PAIR (Optional - for SSH access)
# ============================================================================

resource "aws_key_pair" "ec2_key" {
  count = var.create_key_pair ? 1 : 0

  key_name   = "${var.project_name}-ec2-key-${var.environment}"
  public_key = var.ssh_public_key

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ec2-key-${var.environment}"
    }
  )
}

# ============================================================================
# LAUNCH TEMPLATE
# ============================================================================

resource "aws_launch_template" "app_servers" {
  name_prefix   = "${var.project_name}-lt-${var.environment}-"
  description   = "Launch template for ${var.project_name} application servers"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  key_name      = var.create_key_pair ? aws_key_pair.ec2_key[0].key_name : null

  iam_instance_profile {
    arn = data.aws_iam_instance_profile.lab_profile.arn
  }

  vpc_security_group_ids = [var.security_group_id]

  # Enable detailed monitoring
  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  # User data script to install Docker and configure the instance
  user_data = base64encode(templatefile("${path.module}/user-data-compact-v2.sh", {
    aws_region            = var.aws_region
    environment           = var.environment
    project_name          = var.project_name
    cafeteria_table       = var.cafeteria_table_name
    support_table         = var.support_tickets_table_name
    justifications_table  = var.absence_justifications_table_name
    documents_bucket      = var.documents_bucket_name
    teams_webhook_url     = var.teams_webhook_url
    redis_endpoint        = var.redis_endpoint
  }))

  # EBS configuration
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  # Instance metadata configuration (IMDSv2 required for security)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # Require IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.common_tags,
      {
        Name = "${var.project_name}-app-server-${var.environment}"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      var.common_tags,
      {
        Name = "${var.project_name}-app-volume-${var.environment}"
      }
    )
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-lt-${var.environment}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# AUTO SCALING GROUP
# ============================================================================

resource "aws_autoscaling_group" "app_servers" {
  name                = "${var.project_name}-asg-${var.environment}"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = var.target_group_arns
  health_check_type   = "ELB"
  health_check_grace_period = var.health_check_grace_period

  min_size         = var.min_instances
  max_size         = var.max_instances
  desired_capacity = var.desired_instances

  launch_template {
    id      = aws_launch_template.app_servers.id
    version = "$Latest"
  }

  # Instance refresh configuration for zero-downtime deployments
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = var.health_check_grace_period
    }
  }

  # Termination policies
  termination_policies = ["OldestLaunchTemplate", "OldestInstance"]

  # Enable metrics collection
  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-server-${var.environment}"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.common_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]  # Allow auto-scaling to manage this
  }
}

# ============================================================================
# AUTO SCALING POLICIES
# ============================================================================

# Scale up policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up-${var.environment}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_servers.name
}

# Scale down policy
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-scale-down-${var.environment}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_servers.name
}

# ============================================================================
# CLOUDWATCH ALARMS FOR AUTO SCALING
# ============================================================================

# High CPU alarm - triggers scale up
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_high_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_servers.name
  }

  alarm_description = "This metric monitors EC2 CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_up.arn]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cpu-high-${var.environment}"
    }
  )
}

# Low CPU alarm - triggers scale down
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.project_name}-cpu-low-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_low_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_servers.name
  }

  alarm_description = "This metric monitors EC2 CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cpu-low-${var.environment}"
    }
  )
}

# ============================================================================
# TARGET TRACKING SCALING POLICY (Alternative to step scaling)
# ============================================================================

resource "aws_autoscaling_policy" "target_tracking_cpu" {
  count = var.enable_target_tracking ? 1 : 0

  name                   = "${var.project_name}-target-tracking-${var.environment}"
  autoscaling_group_name = aws_autoscaling_group.app_servers.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.target_cpu_utilization
  }
}
