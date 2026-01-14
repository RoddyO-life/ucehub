terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "UCEHub"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "UCE"
    }
  }
}

# ========================================
# VPC Module
# ========================================

module "vpc" {
  source = "../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr

  availability_zones = var.availability_zones

  public_subnets_cidr       = var.public_subnets_cidr
  private_app_subnets_cidr  = var.private_app_subnets_cidr
  private_data_subnets_cidr = var.private_data_subnets_cidr

  enable_nat_gateway  = true   # Using NAT Gateway for reliable connectivity
  enable_nat_instance = false  # Disabled NAT Instance
  nat_instance_type   = "t3.nano"

  tags = var.tags
}

# ========================================
# Security Groups Module
# ========================================

module "security_groups" {
  source = "../modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id

  enable_bastion       = false  # Disabled for QA to save costs
  bastion_allowed_cidr = "0.0.0.0/0"

  common_tags = var.tags
}

# ========================================
# Load Balancer Module
# ========================================

module "load_balancer" {
  source = "../modules/load-balancer"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id

  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id

  health_check_path   = "/"
  enable_stickiness   = false
  enable_https        = false  # No SSL certificate for QA
  
  enable_deletion_protection = false  # Allow easy cleanup in QA

  common_tags = var.tags
}

# ========================================
# Compute Module (EC2 + Docker + ASG)
# ========================================

module "compute" {
  source = "../modules/compute"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  vpc_id       = module.vpc.vpc_id

  private_subnet_ids = module.vpc.private_app_subnet_ids
  security_group_id  = module.security_groups.ec2_security_group_id
  target_group_arns  = [module.load_balancer.target_group_arn]
  teams_webhook_url  = var.teams_webhook_url

  # Instance configuration
  instance_type             = "t3.nano"  # Smaller instance for easier CPU saturation
  root_volume_size          = 30  # Minimum required by Amazon Linux 2023 AMI
  enable_detailed_monitoring = false  # Save costs in QA

  # Auto Scaling configuration
  min_instances     = 1
  max_instances     = 5
  desired_instances = 2

  health_check_grace_period = 300

  # Scaling policies
  cpu_high_threshold      = 70
  cpu_low_threshold       = 20
  enable_target_tracking  = true
  target_cpu_utilization  = 50

  # Application configuration
  docker_image   = "nginx:alpine"  # Placeholder - update with your Docker image
  container_port = 80

  app_environment_variables = {
    NODE_ENV                   = var.environment
    PROJECT_NAME              = var.project_name
    LOG_LEVEL                 = "info"
    CAFETERIA_TABLE           = module.dynamodb.cafeteria_orders_table_name
    SUPPORT_TICKETS_TABLE     = module.dynamodb.support_tickets_table_name
    ABSENCE_JUSTIFICATIONS_TABLE = module.dynamodb.absence_justifications_table_name
    DOCUMENTS_BUCKET          = module.s3.documents_bucket_name
    NOTIFICATION_EMAIL        = "rjortega@uce.edu.ec"
    TEAMS_WEBHOOK_URL         = var.teams_webhook_url
  }

  # SSH access (disabled for QA to follow security best practices)
  create_key_pair = false
  
  # ECR access (enable if using AWS ECR for Docker images)
  enable_ecr_access = false

  # DynamoDB table names
  cafeteria_table_name              = module.dynamodb.cafeteria_orders_table_name
  support_tickets_table_name        = module.dynamodb.support_tickets_table_name
  absence_justifications_table_name = module.dynamodb.absence_justifications_table_name
  documents_bucket_name             = module.s3.documents_bucket_name

  common_tags = var.tags
}

# ========================================
# DynamoDB Module
# ========================================

module "dynamodb" {
  source = "../modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment

  common_tags = var.tags
}

# ========================================
# S3 Module (Documents Storage)
# ========================================

module "s3" {
  source = "../modules/s3"

  project_name = var.project_name
  environment  = var.environment

  common_tags = var.tags
}
