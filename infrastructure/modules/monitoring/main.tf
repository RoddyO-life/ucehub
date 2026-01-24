# ========================================
# Monitoring Module for UCEHub (Consolidated)
# ========================================

resource "aws_cloudwatch_log_group" "monitoring" {
  name              = "/aws/monitoring/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-monitoring-logs-${var.environment}"
    }
  )
}

# ========================================
# Monitoring Launch Template and Auto Scaling Group
# ========================================

resource "aws_launch_template" "monitoring" {
  name_prefix   = "${var.project_name}-monitoring-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.prometheus_instance_type # Use prometheus type as base

  iam_instance_profile {
    name = "LabInstanceProfile"
  }

  vpc_security_group_ids = [
    var.prometheus_security_group_id,
    var.grafana_security_group_id
  ]

  # Metadata options for AWS SDK to work correctly
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional" # Allow both IMDSv1 and v2 for compatibility
    http_put_response_hop_limit = 2
  }

  user_data = base64encode(templatefile("${path.module}/monitoring-userdata.sh", {
    environment     = var.environment
    project_name    = var.project_name
    alb_dns         = var.alb_dns
  }))

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type           = "gp3"
      volume_size           = 50
      delete_on_termination = true
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.common_tags,
      {
        Name = "${var.project_name}-monitoring-${var.environment}"
        Role = "Monitoring"
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "monitoring" {
  name                = "${var.project_name}-monitoring-asg-${var.environment}"
  vpc_zone_identifier = [var.private_subnet_id]
  target_group_arns  = [
    aws_lb_target_group.prometheus.arn,
    aws_lb_target_group.grafana.arn
  ]

  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.monitoring.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0 # In QA we can destroy before creating to save capacity
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-monitoring-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  depends_on = [var.nat_gateway_id]

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Target Group for Prometheus
resource "aws_lb_target_group" "prometheus" {
  name     = "${var.project_name}-prom-tg-${var.environment}"
  port     = 9090
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/prometheus/-/healthy"
    matcher             = "200"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-prometheus-tg-${var.environment}"
    }
  )
}

# ALB Target Group for Grafana
resource "aws_lb_target_group" "grafana" {
  name     = "${var.project_name}-graf-tg-${var.environment}"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/grafana/api/health"
    matcher             = "200"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-grafana-tg-${var.environment}"
    }
  )
}

# ALB Listener Rules for Prometheus
resource "aws_lb_listener_rule" "prometheus" {
  listener_arn = var.alb_listener_arn
  priority     = 50 # Higher priority to ensure match

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus.arn
  }

  condition {
    path_pattern {
      values = ["/prometheus", "/prometheus/*"]
    }
  }
}

# ALB Listener Rule for Grafana
resource "aws_lb_listener_rule" "grafana" {
  listener_arn = var.alb_listener_arn
  priority     = 51 # Higher priority to ensure match

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  condition {
    path_pattern {
      values = ["/grafana", "/grafana/*", "/api/grafana/*"]
    }
  }
}

# Get existing LabInstanceProfile from AWS Academy
data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}

# Data source for AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
