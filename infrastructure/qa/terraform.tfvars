# ========================================
# UCEHub Infrastructure - QA Environment
# ========================================
# Este archivo NO debe subirse al repositorio
# Copia terraform.tfvars.example y personaliza

# Configuración AWS
aws_region = "us-east-1"

# Proyecto
project_name = "ucehub"
environment  = "qa"

# Networking
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

public_subnets_cidr       = ["10.0.1.0/24", "10.0.2.0/24"]
private_app_subnets_cidr  = ["10.0.10.0/24", "10.0.11.0/24"]
private_data_subnets_cidr = ["10.0.20.0/24", "10.0.21.0/24"]

# Tags
tags = {
  CostCenter = "IT"
  Department = "Engineering"
  Owner      = "rjortega@uce.edu.ec"
}

# Microsoft Teams Webhook URL
# Obtenerlo en: Canal de Teams → ... → Workflows → Incoming Webhook → Copiar URL
teams_webhook_url = "https://uceedu.webhook.office.com/webhookb2/e799dd1e-7afe-4f45-8ec3-ff3a48032b10@8ca52e2b-1d20-4274-9a13-bd76eccb81d1/IncomingWebhook/47511d9bcab74d7fbc07d9b0006ea613/58ad233c-1841-4e86-912f-867fbe44af46/V2ZiPjLSyRzC1UVi4YJPd1FZ41xU6SKhI6jcZlbmbxHe01"
