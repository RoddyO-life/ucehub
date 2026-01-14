# Script para actualizar instancias EC2 del ASG

Write-Host "`n=== ACTUALIZACION DE INSTANCIAS EC2 ===" -ForegroundColor Cyan

# IDs de las instancias viejas
$oldInstances = @("i-0a463bd0fb2e73d49", "i-05ef3f0f5829f690e")

Write-Host "`n📋 Paso 1: Terminando instancias antiguas..." -ForegroundColor Yellow
foreach ($id in $oldInstances) {
    Write-Host "  Terminando $id..." -ForegroundColor Gray
    aws ec2 terminate-instances --instance-ids $id
}

Write-Host "`n⏳ Paso 2: Esperando que ASG cree nuevas instancias..." -ForegroundColor Yellow
Write-Host "   Las nuevas instancias usaran el Launch Template actualizado" -ForegroundColor Cyan

for ($i = 300; $i -gt 0; $i -= 30) {
    Write-Host "   Esperando $i segundos..." -ForegroundColor Gray
    Start-Sleep -Seconds 30
    
    # Probar ALB cada 30 segundos
    try {
        $response = Invoke-WebRequest -Uri "http://ucehub-alb-qa-571412803.us-east-1.elb.amazonaws.com/health" -UseBasicParsing -TimeoutSec 5
        $content = $response.Content | ConvertFrom-Json
        
        if ($content.service -eq "ucehub-auth-service") {
            Write-Host "`n✅ ALB respondiendo con auth-service actualizado!" -ForegroundColor Green
            $content | Format-List
            break
        }
    } catch {
        Write-Host "   ALB todavia no responde, esperando..." -ForegroundColor DarkGray
    }
}

Write-Host "`n🔍 Paso 3: Verificando nuevas instancias..." -ForegroundColor Yellow
aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=ucehub-asg-qa" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[InstanceId,State.Name,LaunchTime,PrivateIpAddress]" --output table

Write-Host "`n✅ Actualizacion completa!" -ForegroundColor Green
Write-Host "Prueba el ALB: http://ucehub-alb-qa-571412803.us-east-1.elb.amazonaws.com/health" -ForegroundColor Cyan
