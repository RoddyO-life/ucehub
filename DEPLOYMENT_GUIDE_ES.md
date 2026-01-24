# 🚀 UCEHub - Deployment Guide

Este documento proporciona instrucciones completas para desplegar la arquitectura de UCEHub de manera escalable y eficiente.

## ⚡ Quick Start (5 minutos)

```powershell
# 1. Ir al directorio del proyecto
cd "C:\Users\ASUS TUF A15\Desktop\TERRAFORM\terraform-infraestructura-como-codigo\3-infra-con-terraform\ucehub"

# 2. Ejecutar el script de inicio rápido
.\quick-start.ps1 -All

# 3. Esperar 2-3 minutos para que los recursos se levanten

# 4. Construir el frontend
cd teams-app
npm install
npm run build
```

## 📋 Requisitos Previos

### Software Requerido
- [AWS CLI v2](https://aws.amazon.com/cli/)
- [Terraform >= 1.0](https://www.terraform.io/downloads)
- [Node.js >= 18](https://nodejs.org/)
- [Git](https://git-scm.com/)
- Docker (opcional, para testing local)
- PowerShell 5.1+ (Windows)

### Credenciales AWS
```bash
# Configurar credenciales
aws configure --profile default

# Verificar acceso
aws sts get-caller-identity
```

### Verificar Webhook de Teams
Obtener la URL en tu canal de Teams:
1. Abrir Teams
2. Ir a tu canal
3. Hacer clic en "..." → "Workflows" → "Incoming Webhook"
4. Copiar la URL
5. Actualizar `terraform.tfvars`

## 📦 Archivos Importantes

```
ucehub/
├── infrastructure/          # Código Terraform
│   ├── qa/                 # Configuración QA
│   │   ├── main.tf        # Módulos principales
│   │   ├── terraform.tfvars
│   │   └── terraform.tfvars.example
│   └── modules/           # Módulos reutilizables
│       ├── vpc/
│       ├── compute/       # EC2 + ASG
│       ├── dynamodb/
│       ├── s3/
│       ├── load-balancer/
│       └── security-groups/
├── services/              # APIs Backend
│   ├── backend/
│   │   ├── server.js      # API Principal
│   │   ├── server-teams.js
│   │   └── Dockerfile
│   └── auth-service/
├── teams-app/             # Frontend React/Vite
│   ├── src/
│   ├── vite.config.ts
│   └── package.json
├── scripts/               # Scripts de utilidad
│   ├── test-apis.sh
│   ├── build-teams-app.sh
│   └── deploy-full.ps1
└── deploy-all.ps1        # Orquestador maestro
```

## 🔧 Configuración

### 1. Configurar terraform.tfvars

```bash
cd infrastructure/qa

# Copiar el archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar con tus valores
# IMPORTANTE:
# - teams_webhook_url: Paste tu URL de webhook
# - aws_region: Debe ser us-east-1 (default)
```

Ejemplo de `terraform.tfvars`:
```hcl
aws_region = "us-east-1"
project_name = "ucehub"
environment = "qa"

vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

teams_webhook_url = "https://uceedu.webhook.office.com/webhookb2/..."

tags = {
  CostCenter = "IT"
  Department = "Engineering"
}
```

### 2. Verificar Variables

```bash
# Confirmar que todas las variables estén en terraform.tfvars
cat terraform.tfvars

# Debe mostrar:
# ✓ aws_region
# ✓ project_name
# ✓ environment
# ✓ vpc_cidr
# ✓ teams_webhook_url
```

## 🚢 Deployment

### Opción 1: Script Automático (Recomendado)

```powershell
# Ir al directorio principal
cd "C:\Users\ASUS TUF A15\Desktop\TERRAFORM\terraform-infraestructura-como-codigo\3-infra-con-terraform\ucehub"

# Ejecutar deployment completo
.\deploy-all.ps1 -Environment qa

# Opciones adicionales:
.\deploy-all.ps1 -Environment qa -SkipFrontend  # Solo infraestructura
.\deploy-all.ps1 -Environment qa -CleanupOnly   # Destruir recursos
```

### Opción 2: Manual Step-by-Step

```bash
cd infrastructure/qa

# Paso 1: Inicializar
terraform init

# Paso 2: Validar
terraform validate

# Paso 3: Planificar
terraform plan -out=tfplan -var-file="terraform.tfvars"

# Paso 4: Aplicar
terraform apply tfplan

# Paso 5: Obtener outputs
terraform output -json > outputs.json
ALB_DNS=$(terraform output -raw alb_dns_name)
echo "ALB: http://$ALB_DNS"
```

### Opción 3: PowerShell Script Interactivo

```powershell
.\infrastructure\qa\deploy-full.ps1 -Environment qa
```

## ⏳ Esperar a que la Infraestructura Esté Lista

La infraestructura tarda aproximadamente 3-5 minutos en estar completamente operativa:

```bash
# Monitor ALB status
aws elbv2 describe-load-balancers --region us-east-1

# Monitor EC2 instances
aws ec2 describe-instances --region us-east-1 \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress]'

# Check API health
curl http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/health

# Watch logs
aws logs tail /aws/ec2/ucehub --follow
```

## 🏗️ Construir Frontend

```bash
# Navegar al directorio del frontend
cd teams-app

# Instalar dependencias
npm ci

# Construir para producción
npm run build

# Outputs:
# ✓ dist/ - Archivos listos para upload a S3
# ✓ dist/index.html - Punto de entrada
# ✓ dist/assets/ - JS, CSS bundles
```

### Conectar Frontend a Backend

El frontend automáticamente conecta a:
```
http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com
```

Variables de entorno (.env.qa):
```bash
VITE_API_URL=http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com
VITE_BACKEND_URL=http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com
```

## ✅ Testing

### Test Rápido de APIs

```bash
# Test health
curl http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/health | jq

# Test cafeteria menu
curl http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/cafeteria/menu | jq

# Test create support ticket
curl -X POST http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/support/ticket \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "Test User",
    "userEmail": "test@example.com",
    "category": "tecnico",
    "subject": "Test Ticket",
    "description": "This is a test",
    "priority": "high"
  }' | jq

# Test create justification
curl -X POST http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/justifications/submit \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "Test User",
    "userEmail": "test@example.com",
    "reason": "Medical appointment",
    "startDate": "2024-01-25",
    "endDate": "2024-01-25"
  }' | jq
```

### Script Automatizado de Testing

```bash
bash scripts/test-apis.sh qa http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com
```

## 🐛 Troubleshooting

### Problema: "Error al enviar la justificación"

**Verificar DynamoDB:**
```bash
aws dynamodb list-tables --region us-east-1

# Debe mostrar:
# - ucehub-absence-justifications-qa
# - ucehub-cafeteria-orders-qa
# - ucehub-support-tickets-qa
```

**Verificar S3:**
```bash
aws s3 ls | grep ucehub-documents

# Debe mostrar un bucket para documentos
```

**Revisar logs del EC2:**
```bash
# Obtener ID de instancia
INSTANCE_ID=$(aws ec2 describe-instances \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

# SSH al servidor
aws ssm start-session --target $INSTANCE_ID --region us-east-1

# Ver logs del Docker
docker logs $(docker ps -q | head -1)
```

### Problema: ALB No Responde

```bash
# Verificar health de targets
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:... \
  --region us-east-1

# Verificar security groups
aws ec2 describe-security-groups \
  --query 'SecurityGroups[?GroupName==`ucehub-alb-qa`]' \
  --region us-east-1
```

### Problema: Teams Webhook No Funciona

```bash
# Verificar URL del webhook
grep -n "teams_webhook_url" infrastructure/qa/terraform.tfvars

# Test manual de webhook
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "@type":"MessageCard",
    "@context":"https://schema.org/extensions",
    "summary":"Test",
    "title":"Test Notification",
    "text":"Testing UCEHub webhook"
  }'
```

## 📊 Monitoring y Logs

### CloudWatch Logs
```bash
# Ver logs en tiempo real
aws logs tail /aws/ec2/ucehub --follow

# Ver últimas 100 líneas
aws logs tail /aws/ec2/ucehub --max-items 100
```

### Métricas de CloudWatch
```bash
# CPU Utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

## 💰 Costos

### Estimación Mensual (QA)
- ALB: ~$15/mes
- EC2 (t3.nano x2): ~$10/mes
- DynamoDB (on-demand): ~$5-20/mes (según uso)
- S3: ~$5-10/mes (según volumen)
- NAT Gateway: ~$32/mes

**Total aproximado: ~$70-90/mes**

### Reducir Costos
- Reducir instancias de 2 a 1
- Usar t3.micro (más económico)
- Eliminar recursos durante no-uso
- Usar DynamoDB provisioned (si tráfico predecible)

## 🛑 Cleanup (Destruir Infraestructura)

```powershell
# Destruir todos los recursos
cd infrastructure\qa
terraform destroy

# O usar el script:
.\..\..\deploy-all.ps1 -Environment qa -CleanupOnly

# Confirmar escribiendo: destroy
```

## 📞 Soporte y Contacto

Para preguntas o problemas:
1. Revisar logs en EC2
2. Verificar CloudWatch
3. Revisar archivo de troubleshooting
4. Contactar al equipo de infraestructura

## 📚 Referencias

- [Documentación de Terraform](https://www.terraform.io/docs)
- [Documentación de AWS](https://docs.aws.amazon.com/)
- [Documentación de Vite](https://vitejs.dev/)
- [Express.js Documentation](https://expressjs.com/)

---

**Última actualización**: Enero 2026
**Versión**: 3.0.0
**Mantenedor**: UCEHub Team
