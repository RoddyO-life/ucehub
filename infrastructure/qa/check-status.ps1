# Verificar estado de las instancias
Write-Host "`n🔍 Verificando estado actual...`n" -ForegroundColor Cyan

# Ver instancias
Write-Host "Instancias en el ASG:" -ForegroundColor Yellow
aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=ucehub-asg-qa" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[InstanceId,LaunchTime]" --output text

Write-Host "`n---`n"

# Probar ALB directamente
Write-Host "Probando ALB (puerto 80):" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/" -UseBasicParsing -TimeoutSec 5
    if ($response.Content -match "UCEHub") {
        Write-Host "✅ Frontend UCEHub detectado" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Respuesta no es UCEHub:" -ForegroundColor Yellow
        Write-Host $response.Content.Substring(0, [Math]::Min(200, $response.Content.Length))
    }
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n---`n"

# Probar health check
Write-Host "Probando /health:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Content:" -ForegroundColor Cyan
    $response.Content
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}
