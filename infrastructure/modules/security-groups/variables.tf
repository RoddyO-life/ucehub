# Security Groups Module - Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., qa, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "enable_bastion" {
  description = "Whether to create bastion host security group"
  type        = bool
  default     = false
}

variable "bastion_allowed_cidr" {
  description = "CIDR block allowed to SSH into bastion host"
  type        = string
  default     = "0.0.0.0/0" # Change to university/VPN IP range for production
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
