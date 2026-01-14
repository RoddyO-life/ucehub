# SOLUCIÓN MANUAL - Refrescar Instancias EC2
# Ejecuta estos comandos UNO POR UNO en tu terminal PowerShell

# ========================================
# Paso 1: Ver instancias actuales
# ========================================
Write-Host "`n1️⃣ Listando instancias actuales del ASG..." -ForegroundColor Cyan
aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=ucehub-asg-qa" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress,LaunchTime]" --output table

Write-Host "`n📋 Copia los Instance IDs de arriba" -ForegroundColor Yellow
Write-Host "`n========================================`n" -ForegroundColor Cyan

# ========================================
# Paso 2: Terminar las instancias
# ========================================
Write-Host "2️⃣ EJECUTA ESTOS COMANDOS manualmente (reemplaza los IDs):`n" -ForegroundColor Cyan
Write-Host 'aws ec2 terminate-instances --instance-ids i-XXXXXXXXX' -ForegroundColor Yellow
Write-Host "Reemplaza i-XXXXXXXXX con cada Instance ID`n" -ForegroundColor Gray

Write-Host "Ejemplo:" -ForegroundColor Green
Write-Host 'aws ec2 terminate-instances --instance-ids i-0a463bd0fb2e73d49' -ForegroundColor White
Write-Host 'Start-Sleep -Seconds 60' -ForegroundColor White
Write-Host 'aws ec2 terminate-instances --instance-ids i-05ef3f0f5829f690e' -ForegroundColor White

Write-Host "`n⚠️ Termina UNA instancia, espera 60 segundos, luego termina la siguiente" -ForegroundColor Yellow
Write-Host "`n========================================`n" -ForegroundColor Cyan

# ========================================
# Paso 3: Esperar nuevas instancias
# ========================================
Write-Host "3️⃣ Después de terminar las instancias, espera 3-5 minutos" -ForegroundColor Cyan
Write-Host "El Auto Scaling Group creará automáticamente nuevas instancias" -ForegroundColor Gray
Write-Host "con el frontend embebido`n" -ForegroundColor Gray

Write-Host "Monitorea el progreso con:" -ForegroundColor Yellow
Write-Host 'aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=ucehub-asg-qa" "Name=instance-state-name,Values=running,pending" --query "Reservations[].Instances[].[InstanceId,State.Name,LaunchTime]" --output table' -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Cyan

# ========================================
# Paso 4: Probar el frontend
# ========================================
Write-Host "4️⃣ Una vez que las nuevas instancias estén 'running', prueba:" -ForegroundColor Cyan
Write-Host "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com`n" -ForegroundColor White

Write-Host "Prueba el health check:" -ForegroundColor Yellow
Write-Host 'Invoke-WebRequest -Uri "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/health" -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json' -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "💡 TIP: Si después de 5 minutos aún ves nginx por defecto," -ForegroundColor Yellow
Write-Host "   espera otros 2-3 minutos para que el ALB detecte las nuevas instancias" -ForegroundColor Gray
Write-Host "========================================`n" -ForegroundColor Cyan
