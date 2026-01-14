# VPC Module

Crea una VPC completa con subnets públicas y privadas en múltiples AZs.

## Características

- VPC con CIDR personalizable
- Multi-AZ deployment (2 zonas de disponibilidad)
- Subnets públicas para ALB y NAT
- Subnets privadas para EC2 (App tier)
- Subnets privadas para RDS (Data tier)
- Internet Gateway
- NAT Instance (económico) o NAT Gateway
- Route Tables configuradas
- Tags consistentes

## Uso

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name = "ucehub"
  environment  = "qa"
  vpc_cidr     = "10.0.0.0/16"
  
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  public_subnets_cidr     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnets_cidr = ["10.0.10.0/24", "10.0.11.0/24"]
  private_data_subnets_cidr = ["10.0.20.0/24", "10.0.21.0/24"]
  
  enable_nat_gateway = false  # Usa NAT Instance
  enable_nat_instance = true
  nat_instance_type = "t3.nano"
  
  tags = {
    Project     = "UCEHub"
    Environment = "qa"
    ManagedBy   = "Terraform"
  }
}
```

## Outputs

- `vpc_id` - ID de la VPC
- `public_subnet_ids` - IDs de subnets públicas
- `private_app_subnet_ids` - IDs de subnets privadas (app)
- `private_data_subnet_ids` - IDs de subnets privadas (data)
- `internet_gateway_id` - ID del Internet Gateway
- `nat_instance_id` - ID de la NAT Instance
