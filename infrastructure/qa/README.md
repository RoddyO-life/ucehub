# 🚀 UCEHub QA Infrastructure - Terraform

Infraestructura completa para ambiente QA usando Terraform.

## 📦 ¿Qué se crea?

```
VPC (10.0.0.0/16)
├── Subnets Públicas (2 AZs)
│   ├── 10.0.1.0/24 (us-east-1a)
│   └── 10.0.2.0/24 (us-east-1b)
├── Subnets Privadas - App (2 AZs)
│   ├── 10.0.10.0/24 (us-east-1a)
│   └── 10.0.11.0/24 (us-east-1b)
├── Subnets Privadas - Data (2 AZs)
│   ├── 10.0.20.0/24 (us-east-1a)
│   └── 10.0.21.0/24 (us-east-1b)
├── Internet Gateway
├── NAT Instance (t3.nano)
└── Route Tables (3)
```

## ⚡ Quick Start

### 1. Instalar Terraform

```powershell
# Con winget
winget install -e --id Hashicorp.Terraform

# Verificar
terraform version
```

### 2. Configurar Variables

```powershell
# Copiar ejemplo
Copy-Item terraform.tfvars.example terraform.tfvars

# Editar (opcional)
notepad terraform.tfvars
```

### 3. Inicializar Terraform

```powershell
cd infrastructure\qa
terraform init
```

### 4. Ver Plan

```powershell
terraform plan
```

### 5. Crear Infraestructura

```powershell
terraform apply
```

Escribe `yes` cuando pregunte.

### 6. Ver Outputs

```powershell
terraform output
```

### 7. Destruir (cuando termines)

```powershell
terraform destroy
```

## 💰 Costos

```
NAT Instance (t3.nano): $3.50/mes
VPC, Subnets, IGW:      $0.00
Route Tables:           $0.00
Elastic IP:             $0.00 (mientras esté asociada)
────────────────────────────────
TOTAL:                  ~$3.50/mes
```

## 📝 Recursos Creados

| Recurso | Cantidad | Descripción |
|---------|----------|-------------|
| VPC | 1 | Red virtual 10.0.0.0/16 |
| Subnets | 6 | 2 públicas, 4 privadas |
| Internet Gateway | 1 | Acceso a internet |
| NAT Instance | 1 | t3.nano para salida privada |
| Route Tables | 3 | Pública, App, Data |
| Elastic IP | 1 | Para NAT Instance |
| Security Group | 1 | Para NAT Instance |

## 🔍 Comandos Útiles

```powershell
# Ver estado
terraform show

# Listar recursos
terraform state list

# Ver recurso específico
terraform state show module.vpc.aws_vpc.main

# Refrescar estado
terraform refresh

# Formatear archivos
terraform fmt -recursive

# Validar configuración
terraform validate

# Ver grafo de dependencias
terraform graph | Out-File -Encoding ascii graph.dot
```

## 📊 Verificar Infraestructura

```powershell
# Listar VPCs
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=UCEHub" --query "Vpcs[*].[VpcId,CidrBlock,Tags[?Key=='Name'].Value|[0]]" --output table

# Listar Subnets
aws ec2 describe-subnets --filters "Name=tag:Project,Values=UCEHub" --query "Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key=='Name'].Value|[0]]" --output table

# Verificar NAT Instance
aws ec2 describe-instances --filters "Name=tag:Project,Values=UCEHub" --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress]" --output table
```

## 🐛 Troubleshooting

**Error: "No valid credential sources found"**
```powershell
aws configure
terraform init
```

**Error: "Error creating VPC: VpcLimitExceeded"**
- AWS Academy limita a 5 VPCs
- Elimina VPCs viejas: `aws ec2 describe-vpcs`

**Error: "Timeout waiting for NAT instance"**
- La AMI de NAT puede tardar
- Espera 5 minutos y vuelve a intentar

**Estado corrupto:**
```powershell
terraform state pull > backup.tfstate
terraform refresh
```

## 🔐 Seguridad

- ✅ Subnets privadas sin acceso directo a internet
- ✅ NAT Instance con source/dest check deshabilitado
- ✅ Security Groups restrictivos
- ✅ Flow logs habilitados (próximamente)

## 🎯 Próximos Pasos

Una vez creada la VPC:

1. **Security Groups** → `infrastructure/modules/security/`
2. **EC2 + Docker** → `infrastructure/modules/compute/`
3. **Load Balancer** → `infrastructure/modules/load-balancer/`
4. **Auto Scaling** → Integrado en compute
5. **RDS + DynamoDB** → `infrastructure/modules/database/`

## 📚 Referencias

- [Terraform AWS VPC](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [NAT Instances](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html)
