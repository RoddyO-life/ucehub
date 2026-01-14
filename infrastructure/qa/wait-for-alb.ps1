Write-Host "`n=== ESPERANDO A QUE LA INSTANCIA ESTE LISTA ===" -ForegroundColor Cyan

$instanceId = "i-03034de5120d1038f"
$maxAttempts = 20
$attempt = 0

while ($attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "`nIntento $attempt de $maxAttempts..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri "http://ucehub-alb-qa-571412803.us-east-1.elb.amazonaws.com/health" -UseBasicParsing -TimeoutSec 5
        
        Write-Host "`n✅ ALB RESPONDE!" -ForegroundColor Green
        Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Cyan
        Write-Host "`nRespuesta:" -ForegroundColor Yellow
        $response.Content | ConvertFrom-Json | Format-List
        
        Write-Host "`n✅ DEPLOYMENT EXITOSO!" -ForegroundColor Green
        break
        
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Error $statusCode - La instancia aun no esta lista" -ForegroundColor DarkYellow
        
        if ($attempt -lt $maxAttempts) {
            Write-Host "Esperando 15 segundos antes del siguiente intento..." -ForegroundColor Gray
            Start-Sleep -Seconds 15
        }
    }
}

if ($attempt -eq $maxAttempts) {
    Write-Host "`n❌ TIMEOUT - La instancia no respondio despues de $($maxAttempts * 15) segundos" -ForegroundColor Red
    Write-Host "`nVerifica los logs de la instancia:" -ForegroundColor Yellow
    Write-Host "aws ec2 get-console-output --instance-id $instanceId --output text > logs.txt" -ForegroundColor Cyan
}
