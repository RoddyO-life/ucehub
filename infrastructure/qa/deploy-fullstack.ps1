Write-Host "`n=== DEPLOY FULLSTACK A AWS ===" -ForegroundColor Cyan

# Paso 1: Obtener instancia actual
Write-Host "`nPaso 1: Obteniendo instancia actual..." -ForegroundColor Yellow
$instance = aws ec2 describe-instances `
    --filters "Name=tag:Name,Values=ucehub-app-server-qa" "Name=instance-state-name,Values=running" `
    --query "Reservations[0].Instances[0].InstanceId" --output text

if ($instance) {
    Write-Host "Instancia encontrada: $instance" -ForegroundColor Cyan
    
    # Paso 2: Terminar instancia
    Write-Host "`nPaso 2: Terminando instancia..." -ForegroundColor Yellow
    aws ec2 terminate-instances --instance-ids $instance | Out-Null
    Write-Host "✅ Instancia terminada" -ForegroundColor Green
} else {
    Write-Host "No hay instancia corriendo, ASG creara una nueva" -ForegroundColor Yellow
}

# Paso 3: Esperar y monitorear
Write-Host "`nPaso 3: Esperando nueva instancia con fullstack..." -ForegroundColor Yellow
Write-Host "Tiempo estimado: 5-7 minutos" -ForegroundColor Gray
Write-Host "  - Creando instancia: 1 min" -ForegroundColor DarkGray
Write-Host "  - Instalando Docker/Node/Nginx: 2 min" -ForegroundColor DarkGray
Write-Host "  - npm install frontend: 3-4 min" -ForegroundColor DarkGray
Write-Host "  - Configurando nginx: 30 seg" -ForegroundColor DarkGray

$url = "http://ucehub-alb-qa-571412803.us-east-1.elb.amazonaws.com"

for ($i = 1; $i -le 25; $i++) {
    Write-Host "`n--- Intento $i/25 (esperando 20 seg) ---" -ForegroundColor Cyan
    Start-Sleep -Seconds 20
    
    try {
        $response = Invoke-WebRequest -Uri "$url/health" -UseBasicParsing -TimeoutSec 5
        
        Write-Host "`n✅ FULLSTACK DEPLOYED!" -ForegroundColor Green
        Write-Host "`nRespuesta:" -ForegroundColor Yellow
        $response.Content | ConvertFrom-Json | Format-List
        
        Write-Host "`nFrontend disponible en:" -ForegroundColor Cyan
        Write-Host "   $url" -ForegroundColor White
        
        Write-Host "`nAPI Backend en:" -ForegroundColor Cyan
        Write-Host "   $url/api/*" -ForegroundColor White
        
        break
    } catch {
        Write-Host "Aun no responde..." -ForegroundColor DarkYellow
    }
}

Write-Host "`nDeployment completo!" -ForegroundColor Green
