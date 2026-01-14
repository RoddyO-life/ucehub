# Load Balancer Module - Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., qa, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where load balancer will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the load balancer"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer"
  type        = string
}

# ============================================================================
# Load Balancer Configuration
# ============================================================================

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the load balancer"
  type        = bool
  default     = false
}

# ============================================================================
# Target Group Configuration
# ============================================================================

variable "health_check_path" {
  description = "Path for health check endpoint"
  type        = string
  default     = "/health"
}

variable "enable_stickiness" {
  description = "Enable session stickiness (session affinity)"
  type        = bool
  default     = false
}

# ============================================================================
# HTTPS Configuration
# ============================================================================

variable "enable_https" {
  description = "Enable HTTPS listener"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of SSL certificate for HTTPS (required if enable_https is true)"
  type        = string
  default     = ""
}

variable "redirect_http_to_https" {
  description = "Redirect HTTP traffic to HTTPS"
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
