# 🚀 INSTRUCCIONES FINALES - EJECUTAR AHORA

## Paso 1: Abrir PowerShell

1. Presionar `Win + X`
2. Seleccionar "Windows PowerShell (Admin)" o "Terminal"
3. Ejecutar:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Paso 2: Navegar al Proyecto

```powershell
cd "C:\Users\ASUS TUF A15\Desktop\TERRAFORM\terraform-infraestructura-como-codigo\3-infra-con-terraform\ucehub"
```

## Paso 3: Verificar Configuración

```powershell
# Ver que tenemos todo
ls -la infrastructure/qa/terraform.tfvars
cat infrastructure/qa/terraform.tfvars
```

## Paso 4: Ejecutar Deploy (OPCIÓN A - RECOMENDADA)

```powershell
# Deployment COMPLETO y automático
.\deploy-all.ps1 -Environment qa
```

Si prefieres más control:
```powershell
# Solo validar
.\deploy-all.ps1 -Environment qa -ValidateOnly

# Validar + Planificar
terraform -C infrastructure/qa plan -out=tfplan -var-file="terraform.tfvars"
```

## Paso 5: Ejecutar Deploy (OPCIÓN B - MANUAL)

```powershell
cd infrastructure/qa

# Inicializar
terraform init -upgrade

# Validar
terraform validate

# Planificar
terraform plan -out=tfplan -var-file="terraform.tfvars"

# Revisar el plan
# Presionar: Y para continuar

# Aplicar
terraform apply tfplan
```

## Paso 6: Monitorear Progreso

Mientras se está deployando:

```powershell
# En OTRA terminal, monitorear recursos
aws ec2 describe-instances --region us-east-1 `
  --query 'Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress]' `
  --output table
```

## Paso 7: Esperar a que ALB esté Ready

```powershell
# Esperar a que responda (tarda ~3 min)
$url = "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/health"
while ($true) {
    try {
        $response = Invoke-WebRequest -Uri $url -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ ALB is ready!" -ForegroundColor Green
            $response.Content | ConvertFrom-Json | ConvertTo-Json
            break
        }
    } catch {
        Write-Host "⏳ Waiting for ALB... (still loading)" -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
}
```

## Paso 8: Construir Frontend

```powershell
cd teams-app
npm install
npm run build
```

## Paso 9: Ejecutar Tests

```powershell
# Test manual de API
$baseUrl = "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com"

# 1. Test health
curl "$baseUrl/health"

# 2. Test menu
curl "$baseUrl/cafeteria/menu"

# 3. Test crear ticket de soporte
curl -X POST "$baseUrl/support/ticket" `
  -H "Content-Type: application/json" `
  -d @"{
    'userName': 'Test User',
    'userEmail': 'test@example.com',
    'category': 'tecnico',
    'subject': 'Test',
    'description': 'Testing',
    'priority': 'high'
}" | ConvertFrom-Json

# 4. Test crear justificación
curl -X POST "$baseUrl/justifications/submit" `
  -H "Content-Type: application/json" `
  -d @"{
    'userName': 'Test User',
    'userEmail': 'test@example.com',
    'reason': 'Medical appointment',
    'startDate': '2024-01-25',
    'endDate': '2024-01-25'
}"
```

## Paso 10: Verificar en Teams

1. Ir a tu canal de Teams
2. Ejecutar uno de los tests arriba
3. Deberías recibir una notificación en Teams

---

## ⚠️ SI ALGO FALLA

### Error: "terraform: command not found"
```powershell
# Instalar Terraform
choco install terraform

# O descargar manualmente:
# https://www.terraform.io/downloads
```

### Error: "AWS credentials not configured"
```powershell
aws configure --region us-east-1

# Te pedirá:
# AWS Access Key ID: [PASTE_YOUR_KEY]
# AWS Secret Access Key: [PASTE_YOUR_SECRET]
# Default region: us-east-1
# Default output format: json
```

### Error: "teams_webhook_url is invalid"
```powershell
# Verificar que esté en terraform.tfvars:
cat infrastructure/qa/terraform.tfvars | grep teams_webhook_url

# Si está vacía, obtener nueva URL en Teams:
# Teams → Channel → ... → Workflows → Incoming Webhook
# Copiar URL y actualizar terraform.tfvars
```

### Error: "ALB no responde después de 10 min"
```powershell
# Revisar logs de EC2
aws logs tail /aws/ec2/ucehub --follow --region us-east-1

# Revisar estado de instancias
aws ec2 describe-instances --region us-east-1 --query 'Reservations[].Instances[].[InstanceId,State.Name]'

# Revisar security groups
aws ec2 describe-security-groups --region us-east-1 --query 'SecurityGroups[?GroupName==`ucehub-alb-qa`]'
```

### Error: "Error al enviar la justificación"
```powershell
# Revisar que DynamoDB table existe
aws dynamodb list-tables --region us-east-1

# Revisar que S3 bucket existe
aws s3 ls | grep ucehub-documents

# Revisar EC2 logs
$INSTANCE_ID = (aws ec2 describe-instances --region us-east-1 --query 'Reservations[0].Instances[0].InstanceId' --output text)
aws ssm start-session --target $INSTANCE_ID --region us-east-1
docker logs $(docker ps -q | head -1)
```

---

## 📊 Verificación Final

Después del deploy, deberías tener:

```
✓ VPC (10.0.0.0/16)
  ├─ 2 Subnets Públicas
  ├─ 2 Subnets Privadas (App)
  ├─ 2 Subnets Privadas (Data)
  └─ NAT Gateway

✓ ALB (Application Load Balancer)
  ├─ Target Group
  └─ Health Checks: Passing

✓ EC2 Auto Scaling Group
  ├─ Min: 1 instancia
  ├─ Max: 5 instancias
  ├─ Desired: 2 instancias
  └─ Scaling Policies: CPU-based

✓ DynamoDB Tables
  ├─ ucehub-cafeteria-orders-qa
  ├─ ucehub-support-tickets-qa
  └─ ucehub-absence-justifications-qa

✓ S3 Bucket
  └─ ucehub-documents-qa-[ACCOUNT_ID]

✓ Security Groups
  ├─ ALB Security Group
  └─ EC2 Security Group
```

---

## 🎯 URLs de Referencia

| Servicio | URL |
|----------|-----|
| **API Base** | http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com |
| **Health** | http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/health |
| **Cafeteria Menu** | http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/cafeteria/menu |
| **Support Tickets** | http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/support/tickets |
| **Justifications** | http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/justifications/list |

---

## 💾 Salvar Estado

Después del deployment exitoso:

```powershell
# Guardar outputs
cd infrastructure/qa
terraform output -json | Out-File outputs.json

# Guardar DNS para referencia
terraform output -raw alb_dns_name | Out-File .alb_dns

# Hacer backup del state
Copy-Item terraform.tfstate terraform.tfstate.backup
```

---

## 🛑 Para Destruir (Si necesitas limpiar)

```powershell
cd infrastructure/qa

# Destroy
terraform destroy -var-file="terraform.tfvars"

# Confirmar escribiendo: yes
```

---

## 📞 Comandos Útiles

```powershell
# Ver estado actual
terraform state list

# Ver variable
terraform var instance_type

# Refresh estado
terraform refresh

# Ver outputs actual
terraform output

# Aplicar sin confirmación (CUIDADO)
terraform apply -auto-approve tfplan
```

---

## ✅ CHECKLIST FINAL

- [ ] AWS CLI instalado y configurado
- [ ] Terraform instalado
- [ ] terraform.tfvars actualizado con webhook URL
- [ ] Teams webhook verificado
- [ ] PowerShell ejecutado como Admin
- [ ] `.\deploy-all.ps1` completado exitosamente
- [ ] ALB responde en /health
- [ ] APIs responden correctamente
- [ ] Frontend compilado
- [ ] Notificación recibida en Teams

---

**¡LISTO! Sigue los pasos arriba y tu arquitectura estará levantada en ~10 minutos.**

Cualquier duda, revisar `DEPLOYMENT_GUIDE_ES.md` o `DEPLOYMENT_FIXES.md`
