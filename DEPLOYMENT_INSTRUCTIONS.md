# 🚀 Guía de Deployment - UCEHub

## ⚡ Quick Start (5 minutos)

```bash
# 1. Clonar repositorio
git clone https://github.com/ucehub/terraform-infraestructura-como-codigo.git
cd 3-infra-con-terraform/ucehub

# 2. Configurar variables
cp infrastructure/qa/terraform.tfvars.example infrastructure/qa/terraform.tfvars
# Editar terraform.tfvars con tus valores

# 3. Deploy QA + Monitoring
cd infrastructure/qa
terraform init
terraform apply

# 4. Obtener URL de ALB
terraform output alb_dns_name

# 5. Verificar servicios
curl http://ALB_DNS/health
curl http://ALB_DNS:9090/-/healthy
curl http://ALB_DNS:3000/api/health
```

---

## 📋 Requisitos Previos

### Herramientas Necesarias
```bash
# Terraform >= 1.5.0
terraform version

# AWS CLI >= 2.13.0
aws --version

# Git
git --version

# Node.js >= 18.0.0 (para frontend)
node --version
npm --version
```

### Credenciales AWS
```bash
# Configurar credenciales
aws configure

# Verificar
aws sts get-caller-identity
```

### Variables de Entorno
```bash
# .env local
export AWS_REGION=us-east-1
export AWS_PROFILE=default
export TF_VAR_project_name=ucehub
export TF_VAR_environment=qa
```

---

## 🏗️ Deployment de Infraestructura

### Paso 1: Inicializar Terraform

```bash
cd infrastructure/qa

# Crear backend S3 si no existe
aws s3 mb s3://ucehub-terraform-state-$(date +%s) --region us-east-1

# Configurar estado remoto
terraform init \
  -backend-config="bucket=ucehub-terraform-state" \
  -backend-config="key=qa/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=terraform-lock"
```

### Paso 2: Validar Configuración

```bash
# Validar sintaxis
terraform validate

# Formatear código
terraform fmt -recursive

# Mostrar plan
terraform plan -out=tfplan
```

### Paso 3: Aplicar Cambios

```bash
# Revisar plan generado
cat tfplan

# Aplicar con aprobación manual
terraform apply tfplan

# O aplicar directamente (sin plan)
terraform apply -auto-approve
```

### Paso 4: Obtener Outputs

```bash
# Listar todos los outputs
terraform output

# Obtener valor específico
terraform output alb_dns_name
terraform output monitoring_urls
```

---

## 🔧 Configuración de Monitoreo

### Paso 1: Agregar Módulo de Monitoring

**Archivo:** `infrastructure/qa/main.tf`

```hcl
# Agregar al final del archivo
module "monitoring" {
  source = "../modules/monitoring"

  project_name                  = var.project_name
  environment                   = var.environment
  vpc_id                        = aws_vpc.main.id
  private_subnet_id            = aws_subnet.private[0].id
  prometheus_security_group_id = aws_security_group.prometheus.id
  grafana_security_group_id    = aws_security_group.grafana.id
  alb_listener_arn             = aws_lb_listener.http.arn
  alb_dns                      = aws_lb.main.dns_name
  nat_gateway_id               = aws_nat_gateway.main.id
  
  common_tags = local.common_tags
}

# Outputs
output "prometheus_url" {
  value = module.monitoring.prometheus_url
}

output "grafana_url" {
  value       = module.monitoring.grafana_url
}

output "grafana_password" {
  value       = module.monitoring.grafana_default_password
  sensitive   = true
}
```

### Paso 2: Crear Security Groups

```hcl
# Agregar a infrastructure/qa/main.tf

resource "aws_security_group" "prometheus" {
  name        = "${var.project_name}-prometheus"
  description = "Security group for Prometheus"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-prometheus-sg"
  })
}

resource "aws_security_group" "grafana" {
  name        = "${var.project_name}-grafana"
  description = "Security group for Grafana"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-grafana-sg"
  })
}
```

### Paso 3: Deploy Monitoring

```bash
# Aplicar solo el módulo de monitoreo
terraform apply -target=module.monitoring -auto-approve

# Verificar
curl -f http://ALB_DNS:9090/-/healthy
curl -f http://ALB_DNS:3000/api/health
```

---

## 🐳 Deployment de Aplicaciones

### Paso 1: Build Backend

```bash
cd services/backend

# Copiar variables de entorno
cp .env.example .env

# Editar .env con credenciales reales
nano .env

# Build Docker image
docker build -t ucehub-backend:latest .

# Push a ECR (opcional)
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

docker tag ucehub-backend:latest \
  123456789.dkr.ecr.us-east-1.amazonaws.com/ucehub-backend:latest

docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/ucehub-backend:latest
```

### Paso 2: Build Frontend

```bash
cd teams-app

# Instalar dependencias
npm install

# Configurar variables de entorno
cat > .env <<EOF
VITE_API_URL=http://ALB_DNS
VITE_TEAMS_APP_ID=00000000-0000-0000-0000-000000000000
EOF

# Build
npm run build

# Resultado: dist/
```

### Paso 3: Deploy Frontend a S3 (opcional)

```bash
# Crear bucket S3
aws s3 mb s3://ucehub-frontend --region us-east-1

# Subir archivos
aws s3 sync dist/ s3://ucehub-frontend/ --delete

# Configurar como sitio web
aws s3 website s3://ucehub-frontend/ \
  --index-document index.html \
  --error-document index.html
```

---

## 🔄 GitHub Actions Setup

### Paso 1: Crear Secrets en GitHub

```bash
# En GitHub repo: Settings → Secrets

# AWS Credentials
AWS_ACCESS_KEY_ID=***
AWS_SECRET_ACCESS_KEY=***

# S3 Backend
TF_STATE_BUCKET=ucehub-terraform-state

# Optional
SLACK_WEBHOOK=https://hooks.slack.com/...
```

### Paso 2: Crear Workflow

**Archivo:** `.github/workflows/qa-to-main.yml`

```yaml
# (Contenido ya incluido en la repo)
# Verificar que existe el archivo
ls -la .github/workflows/qa-to-main.yml
```

### Paso 3: Verificar Workflow

```bash
# En GitHub repo: Actions
# Verificar que el workflow está activo

# Hacer commit a rama QA
git checkout qa
echo "test" >> test.txt
git add .
git commit -m "Test CI/CD"
git push origin qa

# GitHub Actions debería disparar automáticamente
# Ver en: GitHub repo → Actions
```

---

## ✅ Post-Deployment

### Paso 1: Verificar Servicios

```bash
# Health checks
curl -f http://ALB_DNS/health
echo "✓ Backend OK"

# Prometheus
curl -f http://ALB_DNS:9090/-/healthy
echo "✓ Prometheus OK"

# Grafana
curl -f http://ALB_DNS:3000/api/health
echo "✓ Grafana OK"
```

### Paso 2: Configurar Grafana

```bash
# Acceder a Grafana
open "http://ALB_DNS:3000"

# Login
Username: admin
Password: GrafanaAdmin@2024!

# Cambiar contraseña
Profile → Change Password

# Agregar Prometheus datasource
Configuration → Data Sources → Add → Prometheus
URL: http://prometheus:9090

# Crear dashboard
Dashboards → New → Add Panel
Query: rate(http_requests_total[5m])
```

### Paso 3: Configurar Alertas

```hcl
# infrastructure/modules/monitoring/main.tf

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when CPU exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

### Paso 4: Setup Backups

```bash
# Backup de DynamoDB
aws dynamodb create-backup \
  --table-name cafeteria_orders \
  --backup-name "backup-$(date +%Y%m%d-%H%M%S)"

# Backup de S3
aws s3 sync s3://ucehub-documents s3://ucehub-documents-backup/
```

---

## 🛠️ Troubleshooting

### Problema: Terraform state lock

```bash
# Remover lock
terraform force-unlock LOCK_ID

# Ver locks
aws dynamodb scan \
  --table-name terraform-lock \
  --region us-east-1
```

### Problema: EC2 no inicia

```bash
# Revisar userdata logs
aws ec2-instance-connect open-tunnel \
  --instance-id i-xxxxx \
  --local-port 8080

ssh ec2-user@localhost -p 8080
tail -f /var/log/cloud-init-output.log
```

### Problema: Prometheus no recopila métricas

```bash
# Revisar config
curl http://ALB_DNS:9090/api/v1/targets

# Revisar logs
docker logs prometheus
```

### Problema: Grafana no conecta a Prometheus

```bash
# Desde Grafana
Configuration → Data Sources → Edit Prometheus
URL: http://prometheus:9090
Test Connection
```

---

## 📊 Monitoreo Continuo

### Métricas Importantes

```promql
# CPU usage
node_cpu_seconds_total

# Memory available
node_memory_MemAvailable_bytes

# Network throughput
node_network_receive_bytes_total
node_network_transmit_bytes_total

# HTTP requests
http_requests_total
http_request_duration_seconds

# Application errors
application_errors_total
```

### Alertas Recomendadas

```yaml
alerts:
  - name: "High CPU"
    condition: "node_load1 > 4"
    severity: "warning"
  
  - name: "High Memory"
    condition: "node_memory_MemAvailable_bytes < 1000000000"  # 1GB
    severity: "warning"
  
  - name: "Service Down"
    condition: "up == 0"
    severity: "critical"
  
  - name: "High Error Rate"
    condition: "rate(http_requests_total{status=~'5..'}[5m]) > 0.01"
    severity: "warning"
```

---

## 🔐 Seguridad Post-Deploy

### Paso 1: Cambiar Contraseñas

```bash
# Grafana
curl -X PUT http://ALB_DNS:3000/api/user/password \
  -H "Content-Type: application/json" \
  -u admin:GrafanaAdmin@2024! \
  -d '{"password": "NewSecurePassword123!"}'

# MySQL (si aplica)
aws rds modify-db-instance \
  --db-instance-identifier ucehub-db \
  --master-user-password "NewSecurePassword123!" \
  --apply-immediately
```

### Paso 2: Configurar WAF

```hcl
# infrastructure/qa/main.tf

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project_name}-waf"
  scope       = "REGIONAL"
  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0

    action {
      block {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }
}
```

### Paso 3: Habilitar HTTPS

```hcl
# Crear certificado en ACM
resource "aws_acm_certificate" "main" {
  domain_name       = "ucehub.edu.ec"
  validation_method = "DNS"

  tags = local.common_tags
}

# ALB listener HTTPS
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}
```

---

## 📞 Soporte y Contacto

- **Equipo DevOps:** devops@ucehub.edu.ec
- **Issues:** GitHub Issues
- **Chat:** Slack #ucehub-deploy

---

**Versión:** 1.0.0  
**Última actualización:** 2024  
**Status:** ✅ Production Ready
