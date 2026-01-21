# ========================================
# Prometheus Module for UCEHub
# Monitoring and metrics collection
# ========================================

resource "aws_cloudwatch_log_group" "prometheus" {
  name              = "/aws/prometheus/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-prometheus-logs-${var.environment}"
    }
  )
}

resource "aws_ec2_instance" "prometheus" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.prometheus_instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.prometheus_security_group_id]

  user_data = base64encode(templatefile("${path.module}/prometheus-userdata.sh", {
    environment     = var.environment
    project_name    = var.project_name
    alb_dns         = var.alb_dns
  }))

  monitoring                  = true
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-prometheus-${var.environment}"
      Role = "Monitoring"
    }
  )

  depends_on = [var.nat_gateway_id]
}

resource "aws_ec2_instance" "grafana" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.grafana_instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.grafana_security_group_id]

  user_data = base64encode(templatefile("${path.module}/grafana-userdata.sh", {
    environment     = var.environment
    project_name    = var.project_name
    prometheus_ip   = aws_ec2_instance.prometheus.private_ip
  }))

  monitoring                  = true
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size = 30
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-grafana-${var.environment}"
      Role = "Visualization"
    }
  )

  depends_on = [
    aws_ec2_instance.prometheus,
    var.nat_gateway_id
  ]
}

# ALB Target Group for Prometheus
resource "aws_lb_target_group" "prometheus" {
  name     = "${var.project_name}-prometheus-tg-${var.environment}"
  port     = 9090
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/-/healthy"
    matcher             = "200"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-prometheus-tg-${var.environment}"
    }
  )
}

resource "aws_lb_target_group_attachment" "prometheus" {
  target_group_arn = aws_lb_target_group.prometheus.arn
  target_id        = aws_ec2_instance.prometheus.id
  port             = 9090
}

# ALB Target Group for Grafana
resource "aws_lb_target_group" "grafana" {
  name     = "${var.project_name}-grafana-tg-${var.environment}"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/api/health"
    matcher             = "200"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-grafana-tg-${var.environment}"
    }
  )
}

resource "aws_lb_target_group_attachment" "grafana" {
  target_group_arn = aws_lb_target_group.grafana.arn
  target_id        = aws_ec2_instance.grafana.id
  port             = 3000
}

# ALB Listener Rules for Prometheus
resource "aws_lb_listener_rule" "prometheus" {
  listener_arn = var.alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus.arn
  }

  condition {
    path_pattern {
      values = ["/prometheus/*"]
    }
  }
}

# ALB Listener Rule for Grafana
resource "aws_lb_listener_rule" "grafana" {
  listener_arn = var.alb_listener_arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  condition {
    path_pattern {
      values = ["/grafana/*", "/api/grafana/*"]
    }
  }
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
