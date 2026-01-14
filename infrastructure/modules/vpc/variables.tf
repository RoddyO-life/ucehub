variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (qa, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidad"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets_cidr" {
  description = "CIDR blocks para subnets públicas"
  type        = list(string)
}

variable "private_app_subnets_cidr" {
  description = "CIDR blocks para subnets privadas (app tier)"
  type        = list(string)
}

variable "private_data_subnets_cidr" {
  description = "CIDR blocks para subnets privadas (data tier)"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway (caro: $32/mes)"
  type        = bool
  default     = false
}

variable "enable_nat_instance" {
  description = "Habilitar NAT Instance (económico: $3.50/mes)"
  type        = bool
  default     = true
}

variable "nat_instance_type" {
  description = "Tipo de instancia para NAT"
  type        = string
  default     = "t3.nano"
}

variable "tags" {
  description = "Tags adicionales para recursos"
  type        = map(string)
  default     = {}
}
