# Load Balancer Module
# Creates Application Load Balancer, Target Groups, and Listeners

# ============================================================================
# APPLICATION LOAD BALANCER
# ============================================================================

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  idle_timeout = 60

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-alb-${var.environment}"
    }
  )
}

# ============================================================================
# TARGET GROUP
# ============================================================================

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Health check configuration
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  # Deregistration delay (connection draining)
  deregistration_delay = 30

  # Stickiness (session affinity)
  stickiness {
    enabled         = var.enable_stickiness
    type            = "lb_cookie"
    cookie_duration = 86400  # 24 hours
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-tg-${var.environment}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# HTTP LISTENER (Port 80)
# ============================================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Default action - forward to target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-http-listener-${var.environment}"
    }
  )
}

# ============================================================================
# HTTPS LISTENER (Port 443) - Optional
# ============================================================================

resource "aws_lb_listener" "https" {
  count = var.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-https-listener-${var.environment}"
    }
  )
}

# HTTP to HTTPS redirect rule (if HTTPS is enabled)
resource "aws_lb_listener_rule" "redirect_http_to_https" {
  count = var.enable_https && var.redirect_http_to_https ? 1 : 0

  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-http-redirect-${var.environment}"
    }
  )
}

# ============================================================================
# LISTENER RULES - Custom routing (optional)
# ============================================================================

# Example: Route /api/* to API target group (if you have microservices)
# Uncomment and customize as needed
# resource "aws_lb_listener_rule" "api" {
#   listener_arn = aws_lb_listener.http.arn
#   priority     = 10
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.api.arn
#   }
#
#   condition {
#     path_pattern {
#       values = ["/api/*"]
#     }
#   }
# }

# ============================================================================
# CLOUDWATCH ALARMS FOR ALB
# ============================================================================

# High number of unhealthy targets alarm
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.project_name}-unhealthy-targets-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Alert when there are unhealthy targets"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-unhealthy-targets-${var.environment}"
    }
  )
}

# High response time alarm
resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "${var.project_name}-high-response-time-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1.0  # 1 second
  alarm_description   = "Alert when response time is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-high-response-time-${var.environment}"
    }
  )
}

# High 5XX errors alarm
resource "aws_cloudwatch_metric_alarm" "high_5xx_errors" {
  alarm_name          = "${var.project_name}-high-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when 5XX errors are high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-high-5xx-errors-${var.environment}"
    }
  )
}
