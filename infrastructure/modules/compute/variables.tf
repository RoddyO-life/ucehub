# Compute Module - Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., qa, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EC2 instances"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}

variable "target_group_arns" {
  description = "List of target group ARNs for the Auto Scaling Group"
  type        = list(string)
  default     = []
}

# ============================================================================
# Instance Configuration
# ============================================================================

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 30
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring (additional cost)"
  type        = bool
  default     = false
}

# ============================================================================
# Auto Scaling Configuration
# ============================================================================

variable "min_instances" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 6
}

variable "desired_instances" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health"
  type        = number
  default     = 300
}

# ============================================================================
# Scaling Policy Configuration
# ============================================================================

variable "cpu_high_threshold" {
  description = "CPU percentage threshold to trigger scale up"
  type        = number
  default     = 70
}

variable "cpu_low_threshold" {
  description = "CPU percentage threshold to trigger scale down"
  type        = number
  default     = 20
}

variable "enable_target_tracking" {
  description = "Enable target tracking scaling policy (alternative to step scaling)"
  type        = bool
  default     = true
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization percentage for target tracking"
  type        = number
  default     = 50
}

# ============================================================================
# Application Configuration
# ============================================================================

variable "docker_image" {
  description = "Docker image to run on EC2 instances"
  type        = string
  default     = "nginx:alpine"  # Default placeholder
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "app_environment_variables" {
  description = "Environment variables to pass to the application"
  type        = map(string)
  default     = {}
}

# ============================================================================
# SSH Access Configuration
# ============================================================================

variable "create_key_pair" {
  description = "Whether to create an EC2 key pair for SSH access"
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "Public SSH key content (only used if create_key_pair is true)"
  type        = string
  default     = ""
}

# ============================================================================
# IAM Configuration
# ============================================================================

variable "enable_ecr_access" {
  description = "Enable ECR access for pulling Docker images"
  type        = bool
  default     = false
}

# ============================================================================
# Tags
# ============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "teams_webhook_url" {
  description = "Microsoft Teams Incoming Webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

# ============================================================================
# DynamoDB Tables
# ============================================================================

variable "cafeteria_table_name" {
  description = "Name of the DynamoDB table for cafeteria orders"
  type        = string
  default     = ""
}

variable "support_tickets_table_name" {
  description = "Name of the DynamoDB table for support tickets"
  type        = string
  default     = ""
}

variable "absence_justifications_table_name" {
  description = "Name of the DynamoDB table for absence justifications"
  type        = string
  default     = ""
}

variable "documents_bucket_name" {
  description = "Name of the S3 bucket for storing documents"
  type        = string
  default     = ""
}
