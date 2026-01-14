Write-Host "`n=== DIAGNOSTICO ALB 502 ===" -ForegroundColor Red

Write-Host "`nPaso 1: Obteniendo ID de instancia..." -ForegroundColor Yellow
$instanceId = aws ec2 describe-instances --filters "Name=tag:Name,Values=ucehub-app-server-qa" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text
Write-Host "Instancia: $instanceId" -ForegroundColor Cyan

Write-Host "`nPaso 2: Verificando logs del user-data..." -ForegroundColor Yellow
Write-Host "Obteniendo ultimas 50 lineas de console output..." -ForegroundColor Gray
$logs = aws ec2 get-console-output --instance-id $instanceId --output text
$logs -split "`n" | Select-Object -Last 50

Write-Host "`nPaso 3: El contenedor Docker esta corriendo?" -ForegroundColor Yellow
Write-Host "Necesitas conectarte por Session Manager para verificar:" -ForegroundColor Gray
Write-Host "  aws ssm start-session --target $instanceId" -ForegroundColor Cyan
Write-Host "  Luego ejecuta: docker ps" -ForegroundColor Cyan

Write-Host "`n=== POSIBLES PROBLEMAS ===" -ForegroundColor Yellow
Write-Host "1. El user-data aun esta ejecutandose (espera 2-3 min)" -ForegroundColor White
Write-Host "2. Docker no inicio correctamente" -ForegroundColor White
Write-Host "3. El contenedor fallo al construir" -ForegroundColor White
Write-Host "4. El puerto 80 no esta expuesto correctamente" -ForegroundColor White
