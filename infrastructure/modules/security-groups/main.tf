# Security Groups Module
# Creates security groups for ALB, EC2, RDS, and Bastion

# ============================================================================
# LOAD BALANCER SECURITY GROUP
# ============================================================================
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-alb-sg-${var.environment}"
    }
  )
}

# Allow HTTP from anywhere
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from internet"
  
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  tags = merge(
    var.common_tags,
    {
      Name = "alb-http-ingress"
    }
  )
}

# Allow HTTPS from anywhere
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from internet"
  
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  tags = merge(
    var.common_tags,
    {
      Name = "alb-https-ingress"
    }
  )
}

# Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"
  
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = merge(
    var.common_tags,
    {
      Name = "alb-all-egress"
    }
  )
}

# ============================================================================
# EC2 INSTANCES SECURITY GROUP
# ============================================================================
resource "aws_security_group" "ec2_instances" {
  name        = "${var.project_name}-ec2-sg-${var.environment}"
  description = "Security group for EC2 instances running Docker containers"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ec2-sg-${var.environment}"
    }
  )
}

# Allow HTTP from ALB only
resource "aws_vpc_security_group_ingress_rule" "ec2_from_alb" {
  security_group_id = aws_security_group.ec2_instances.id
  description       = "Allow HTTP from ALB"
  
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"

  tags = merge(
    var.common_tags,
    {
      Name = "ec2-http-from-alb"
    }
  )
}

# Allow SSH from Bastion only
resource "aws_vpc_security_group_ingress_rule" "ec2_ssh_from_bastion" {
  count = var.enable_bastion ? 1 : 0

  security_group_id = aws_security_group.ec2_instances.id
  description       = "Allow SSH from Bastion"
  
  referenced_security_group_id = aws_security_group.bastion[0].id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"

  tags = merge(
    var.common_tags,
    {
      Name = "ec2-ssh-from-bastion"
    }
  )
}

# Allow all traffic within the same security group (for microservices communication)
resource "aws_vpc_security_group_ingress_rule" "ec2_self" {
  security_group_id = aws_security_group.ec2_instances.id
  description       = "Allow all traffic from instances in same security group"
  
  referenced_security_group_id = aws_security_group.ec2_instances.id
  ip_protocol                  = "-1"

  tags = merge(
    var.common_tags,
    {
      Name = "ec2-self-ingress"
    }
  )
}

# Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "ec2_all" {
  security_group_id = aws_security_group.ec2_instances.id
  description       = "Allow all outbound traffic"
  
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = merge(
    var.common_tags,
    {
      Name = "ec2-all-egress"
    }
  )
}

# ============================================================================
# BASTION HOST SECURITY GROUP (Optional)
# ============================================================================
resource "aws_security_group" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name        = "${var.project_name}-bastion-sg-${var.environment}"
  description = "Security group for Bastion host"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-bastion-sg-${var.environment}"
    }
  )
}

# Allow SSH from specific CIDR (e.g., university network or VPN)
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  count = var.enable_bastion ? 1 : 0

  security_group_id = aws_security_group.bastion[0].id
  description       = "Allow SSH from authorized IPs"
  
  cidr_ipv4   = var.bastion_allowed_cidr
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"

  tags = merge(
    var.common_tags,
    {
      Name = "bastion-ssh-ingress"
    }
  )
}

# Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  count = var.enable_bastion ? 1 : 0

  security_group_id = aws_security_group.bastion[0].id
  description       = "Allow all outbound traffic"
  
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = merge(
    var.common_tags,
    {
      Name = "bastion-all-egress"
    }
  )
}

# ============================================================================
# RDS SECURITY GROUP
# ============================================================================
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "Security group for RDS PostgreSQL instances"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-rds-sg-${var.environment}"
    }
  )
}

# Allow PostgreSQL from EC2 instances
resource "aws_vpc_security_group_ingress_rule" "rds_from_ec2" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow PostgreSQL from EC2 instances"
  
  referenced_security_group_id = aws_security_group.ec2_instances.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"

  tags = merge(
    var.common_tags,
    {
      Name = "rds-postgres-from-ec2"
    }
  )
}

# Allow PostgreSQL from Bastion (for database management)
resource "aws_vpc_security_group_ingress_rule" "rds_from_bastion" {
  count = var.enable_bastion ? 1 : 0

  security_group_id = aws_security_group.rds.id
  description       = "Allow PostgreSQL from Bastion"
  
  referenced_security_group_id = aws_security_group.bastion[0].id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"

  tags = merge(
    var.common_tags,
    {
      Name = "rds-postgres-from-bastion"
    }
  )
}

# RDS typically doesn't need outbound rules, but we add it for completeness
resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
  
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = merge(
    var.common_tags,
    {
      Name = "rds-all-egress"
    }
  )
}
