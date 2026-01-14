#!/usr/bin/env powershell
# Restart UCEHub deployment with updated user-data

Write-Host "`n=== UCEHub Deployment Restart ===" -ForegroundColor Cyan

# Get running instances
Write-Host "`n1. Buscando instancias actuales..." -ForegroundColor Yellow
$instances = aws ec2 describe-instances `
    --filters "Name=tag:aws:autoscaling:groupName,Values=ucehub-asg-qa" `
              "Name=instance-state-name,Values=running" `
    --query "Reservations[].Instances[].InstanceId" `
    --output text

if ($instances) {
    $instanceArray = $instances -split '\s+'
    Write-Host "Encontradas $($instanceArray.Count) instancia(s): $($instances)" -ForegroundColor White
    
    # Terminate instances
    Write-Host "`n2. Terminando instancias..." -ForegroundColor Yellow
    aws ec2 terminate-instances --instance-ids $instances
    
    Write-Host "`nInstancias terminadas. ASG creara nuevas instancias en 2-3 minutos." -ForegroundColor Green
} else {
    Write-Host "No hay instancias corriendo actualmente" -ForegroundColor Gray
}

# Monitor new instances
Write-Host "`n3. Monitoreando nuevas instancias..." -ForegroundColor Yellow
Write-Host "Esperando 30 segundos antes de verificar..." -ForegroundColor Gray
Start-Sleep -Seconds 30

for ($i = 1; $i -le 15; $i++) {
    Write-Host "`nIntento $i/15:" -ForegroundColor Cyan
    
    $newInstances = aws ec2 describe-instances `
        --filters "Name=tag:aws:autoscaling:groupName,Values=ucehub-asg-qa" `
                  "Name=instance-state-name,Values=running,pending" `
        --query "Reservations[].Instances[].[InstanceId,State.Name,LaunchTime]" `
        --output table
    
    if ($newInstances) {
        Write-Host $newInstances
        
        # Check ALB health
        Write-Host "`nVerificando ALB health..." -ForegroundColor Yellow
        try {
            $response = Invoke-WebRequest -Uri "http://ucehub-alb-qa-571412803.us-east-1.elb.amazonaws.com/health" -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Host "`nSUCCESS! Aplicacion respondiendo:" -ForegroundColor Green
                $response.Content | ConvertFrom-Json | Format-List
                Write-Host "`nFrontend URL: http://ucehub-alb-qa-571412803.us-east-1.elb.amazonaws.com" -ForegroundColor Cyan
                Write-Host "API URL: http://ucehub-alb-qa-571412803.us-east-1.elb.amazonaws.com/api/health" -ForegroundColor Cyan
                break
            }
        } catch {
            Write-Host "ALB aun no responde (esperado durante inicializacion)" -ForegroundColor Gray
        }
    } else {
        Write-Host "No hay nuevas instancias aun..." -ForegroundColor Gray
    }
    
    if ($i -lt 15) {
        Write-Host "Esperando 30 segundos..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
    }
}

Write-Host "`n=== Script Complete ===" -ForegroundColor Cyan
