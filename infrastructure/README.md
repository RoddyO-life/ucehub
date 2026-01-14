# Terraform Infrastructure as Code

Este directorio contiene toda la infraestructura de UCEHub como código usando Terraform.

## 📁 Estructura

```
infrastructure/
├── modules/              # Módulos reutilizables
│   ├── vpc/             # Red virtual (VPC, subnets, IGW, NAT)
│   ├── security/        # Security Groups
│   ├── compute/         # EC2, Launch Templates, ASG
│   ├── load-balancer/   # ALB, Target Groups
│   └── database/        # RDS, DynamoDB
├── qa/                  # Ambiente QA
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── prod/                # Ambiente Producción
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
└── shared/              # Recursos compartidos (S3, IAM)
```

## 🚀 Quick Start

### 1. Instalar Terraform

```powershell
# Opción A: Con winget
winget install -e --id Hashicorp.Terraform

# Opción B: Con Chocolatey
choco install terraform

# Verificar instalación
terraform version
```

### 2. Inicializar Terraform

```powershell
cd infrastructure/qa
terraform init
```

### 3. Planificar Cambios

```powershell
terraform plan
```

### 4. Aplicar Infraestructura

```powershell
terraform apply
```

### 5. Destruir (cuando termines)

```powershell
terraform destroy
```

## 💰 Estimación de Costos

### QA Environment:
- VPC: $0
- NAT Instance: $3.50/mes
- ALB: $16/mes
- EC2 (2x t3.micro): $15/mes
- RDS (db.t3.micro): $13/mes
- **TOTAL: ~$47/mes**

### Production Environment:
- VPC: $0
- NAT Instance: $3.50/mes
- ALB: $16/mes
- EC2 (3x t3.micro): $23/mes
- RDS Multi-AZ: $26/mes
- **TOTAL: ~$68/mes**

## 🔐 Variables Sensibles

No subas credenciales al repo. Usa:

```powershell
# Crear archivo de secrets
cp terraform.tfvars.example terraform.tfvars

# Editar con tus valores
notepad terraform.tfvars
```

## 📝 Comandos Útiles

```powershell
# Ver estado actual
terraform show

# Listar recursos
terraform state list

# Ver outputs
terraform output

# Formatear código
terraform fmt -recursive

# Validar configuración
terraform validate

# Crear workspace para testing
terraform workspace new test
terraform workspace select qa
```

## 🔄 Workflow Recomendado

1. **Desarrollo Local:**
   ```powershell
   cd infrastructure/qa
   terraform plan -out=tfplan
   ```

2. **Review:**
   - Revisa el plan
   - Verifica costos estimados

3. **Apply:**
   ```powershell
   terraform apply tfplan
   ```

4. **Testing:**
   - Prueba la infraestructura
   - Verifica conectividad

5. **Cleanup:**
   ```powershell
   terraform destroy -auto-approve
   ```

## 🐛 Troubleshooting

**Error: "AWS credentials not found"**
```powershell
aws configure
terraform init
```

**Error: "Resource already exists"**
```powershell
terraform import <resource> <id>
```

**Estado corrupto:**
```powershell
terraform state pull > backup.tfstate
terraform state rm <resource>
```

## 📚 Referencias

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [AWS Architecture](https://aws.amazon.com/architecture/)
