# UCEHub - Production Environment
# This configuration is managed via Pull Request
# Reviewer: @JuanGuevara90

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

  enable_nat_gateway  = true
  enable_nat_instance = false
  nat_instance_type   = "t3.micro"

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
  vpc_cidr     = var.vpc_cidr

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

  public_subnet_ids   = module.vpc.public_subnet_ids
  security_group_id   = module.security_groups.alb_security_group_id
  health_check_path   = "/"
  enable_stickiness   = false
  enable_https        = false  # Enable in production with SSL certificate
  
  enable_deletion_protection = true  # Protected in production

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

  # Production instance configuration
  instance_type             = "t3.small"  # Larger for production
  root_volume_size          = 30
  enable_detailed_monitoring = true  # Enabled for production

  # Production Auto Scaling configuration
  min_instances     = 2   # Minimum 2 for HA
  max_instances     = 10  # Higher max for production
  desired_instances = 3

  health_check_grace_period = 300

  # Scaling policies
  cpu_high_threshold      = 70
  cpu_low_threshold       = 30
  enable_target_tracking  = true
  target_cpu_utilization  = 60

  # Application configuration
  docker_image   = "nginx:alpine"
  container_port = 80

  app_environment_variables = {
    NODE_ENV                     = var.environment
    PROJECT_NAME                 = var.project_name
    LOG_LEVEL                    = "warn"
    CAFETERIA_TABLE              = module.dynamodb.cafeteria_orders_table_name
    SUPPORT_TICKETS_TABLE        = module.dynamodb.support_tickets_table_name
    ABSENCE_JUSTIFICATIONS_TABLE = module.dynamodb.absence_justifications_table_name
    DOCUMENTS_BUCKET             = module.s3.documents_bucket_name
    TEAMS_WEBHOOK_URL            = var.teams_webhook_url
    REDIS_ENDPOINT               = module.cache.redis_endpoint
  }

  # SSH access (disabled for production)
  create_key_pair = false
  
  # ECR access
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

# ========================================
# Cache Module (Redis)
# ========================================
module "cache" {
  source = "../modules/cache"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  private_data_subnet_ids = module.vpc.private_data_subnet_ids
  ec2_security_group_id  = module.security_groups.ec2_security_group_id

  common_tags = var.tags
}
