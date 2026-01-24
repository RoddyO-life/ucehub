variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (qa o prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs de subnets para el cluster de Redis"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Lista de Security Group IDs que pueden acceder a Redis"
  type        = list(string)
}

variable "node_type" {
  description = "Tipo de instancia para el nodo de Redis"
  type        = string
  default     = "cache.t3.micro"
}

variable "tags" {
  description = "Tags comunes"
  type        = map(string)
}
