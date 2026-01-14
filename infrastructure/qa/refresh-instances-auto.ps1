# Script para refrescar instancias EC2 del ASG automáticamente
$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "REFRESCANDO INSTANCIAS EC2" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Obtener el nombre del ASG desde Terraform outputs
Write-Host "`n📋 Obteniendo información del Auto Scaling Group..." -ForegroundColor Yellow
$asgName = terraform output -raw asg_name

if (-not $asgName) {
    Write-Host "❌ No se pudo obtener el nombre del ASG" -ForegroundColor Red
    exit 1
}

Write-Host "ASG encontrado: $asgName" -ForegroundColor Green

# Obtener instancias actuales del ASG
Write-Host "`n🔍 Obteniendo instancias actuales..." -ForegroundColor Yellow
$instances = aws autoscaling describe-auto-scaling-groups `
    --auto-scaling-group-names $asgName `
    --query "AutoScalingGroups[0].Instances[?HealthStatus=='Healthy' && LifecycleState=='InService'].InstanceId" `
    --output text

if (-not $instances) {
    Write-Host "❌ No hay instancias saludables en el ASG" -ForegroundColor Red
    exit 1
}

$instanceArray = $instances -split '\s+'
Write-Host "Instancias encontradas: $($instanceArray.Count)" -ForegroundColor Cyan
foreach ($id in $instanceArray) {
    Write-Host "  - $id" -ForegroundColor Gray
}

# Terminar las instancias una por una
Write-Host "`n🔄 Terminando instancias para forzar reemplazo..." -ForegroundColor Yellow
foreach ($id in $instanceArray) {
    Write-Host "`nTerminando instancia: $id" -ForegroundColor Yellow
    aws ec2 terminate-instances --instance-ids $id | Out-Null
    
    Write-Host "⏳ Esperando 60 segundos antes de terminar la siguiente..." -ForegroundColor Gray
    Start-Sleep -Seconds 60
}

# Esperar a que ASG cree nuevas instancias
Write-Host "`n⏳ Esperando a que el ASG cree nuevas instancias..." -ForegroundColor Yellow
Write-Host "Las nuevas instancias usarán el Launch Template actualizado con el frontend embebido" -ForegroundColor Cyan

$maxWaitTime = 300  # 5 minutos
$waitInterval = 15
$elapsed = 0

while ($elapsed -lt $maxWaitTime) {
    Start-Sleep -Seconds $waitInterval
    $elapsed += $waitInterval
    
    # Verificar instancias en servicio
    $healthyCount = aws autoscaling describe-auto-scaling-groups `
        --auto-scaling-group-names $asgName `
        --query "AutoScalingGroups[0].Instances[?HealthStatus=='Healthy' && LifecycleState=='InService'] | length(@)" `
        --output text
    
    Write-Host "Tiempo transcurrido: $elapsed s | Instancias saludables: $healthyCount" -ForegroundColor Gray
    
    if ([int]$healthyCount -ge 2) {
        Write-Host "`n✅ Nuevas instancias están en servicio!" -ForegroundColor Green
        break
    }
}

# Obtener ALB URL
Write-Host "`n🔍 Obteniendo URL del Load Balancer..." -ForegroundColor Yellow
$albUrl = terraform output -raw alb_dns_name

# Probar el frontend
Write-Host "`n🌐 Probando el frontend..." -ForegroundColor Yellow
Start-Sleep -Seconds 10  # Dar tiempo para que el target group se actualice

try {
    $response = Invoke-WebRequest -Uri "http://$albUrl/" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200 -and $response.Content -match "UCEHub") {
        Write-Host "✅ Frontend funcionando correctamente!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Frontend responde pero el contenido no es el esperado" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ No se pudo verificar el frontend: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Espera 1-2 minutos más para que el ALB registre las nuevas instancias" -ForegroundColor Cyan
}

# Probar health check
Write-Host "`n🏥 Probando health check..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$albUrl/health" -UseBasicParsing -TimeoutSec 10
    $healthData = $response.Content | ConvertFrom-Json
    Write-Host "✅ Health check OK:" -ForegroundColor Green
    Write-Host "   Service: $($healthData.service)" -ForegroundColor Cyan
    Write-Host "   Status: $($healthData.status)" -ForegroundColor Cyan
    Write-Host "   Instance: $($healthData.instance)" -ForegroundColor Cyan
} catch {
    Write-Host "⚠️ Health check no disponible todavía" -ForegroundColor Yellow
}

# Listar nuevas instancias
Write-Host "`n📋 Nuevas instancias en el ASG:" -ForegroundColor Yellow
aws ec2 describe-instances `
    --filters "Name=tag:aws:autoscaling:groupName,Values=$asgName" "Name=instance-state-name,Values=running" `
    --query "Reservations[].Instances[].[InstanceId,State.Name,LaunchTime,PrivateIpAddress]" `
    --output table

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✅ ACTUALIZACIÓN COMPLETA" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`n🌐 Accede a tu aplicación:" -ForegroundColor Yellow
Write-Host "   http://$albUrl" -ForegroundColor Cyan
Write-Host "`nSi ves la página de nginx por defecto, espera 1-2 minutos más" -ForegroundColor Gray
