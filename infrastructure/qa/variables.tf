variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "ucehub"
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "qa"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets_cidr" {
  description = "CIDR blocks para subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnets_cidr" {
  description = "CIDR blocks para subnets privadas (app)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "private_data_subnets_cidr" {
  description = "CIDR blocks para subnets privadas (data)"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default = {
    CostCenter = "IT"
    Department = "Engineering"
  }
}

variable "teams_webhook_url" {
  description = "Microsoft Teams Incoming Webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}
