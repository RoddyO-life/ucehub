# Script de Diagnóstico UCEHub

Write-Host "=== DIAGNOSTICO UCEHUB ===" -ForegroundColor Cyan

# 1. Health Check
Write-Host "`n1. Verificando Health Check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/health" -Method Get
    Write-Host "✓ Backend respondiendo" -ForegroundColor Green
    Write-Host "  Service: $($health.service)" -ForegroundColor Gray
    Write-Host "  Instance: $($health.instance)" -ForegroundColor Gray
    Write-Host "  Tables configuradas:" -ForegroundColor Gray
    Write-Host "    - Cafeteria: $($health.config.cafeteria_table)" -ForegroundColor Gray
    Write-Host "    - Support: $($health.config.support_table)" -ForegroundColor Gray
    Write-Host "    - Justifications: $($health.config.justifications_table)" -ForegroundColor Gray
    Write-Host "    - Documents Bucket: $($health.config.documents_bucket)" -ForegroundColor Gray
    Write-Host "    - Teams Webhook: $($health.config.teams_webhook_configured)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Error en health check: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. Test API Cafeteria Menu
Write-Host "`n2. Probando API de Cafeteria (Menu)..." -ForegroundColor Yellow
try {
    $menu = Invoke-RestMethod -Uri "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/api/cafeteria/menu" -Method Get
    Write-Host "✓ Menu obtenido: $($menu.data.Count) items" -ForegroundColor Green
} catch {
    Write-Host "✗ Error obteniendo menu: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Test API Crear Orden
Write-Host "`n3. Probando API de Cafeteria (Crear Orden)..." -ForegroundColor Yellow
try {
    $orderData = @{
        items = @(
            @{ id = 1; name = "Cafe"; price = 1.50; quantity = 2 }
        )
        total = 3.00
        userEmail = "test@uce.edu.ec"
        userName = "Usuario Test"
        paymentMethod = "Efectivo"
    } | ConvertTo-Json

    $order = Invoke-RestMethod -Uri "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/api/cafeteria/order" -Method Post -Body $orderData -ContentType "application/json"
    Write-Host "✓ Orden creada: $($order.data.orderId)" -ForegroundColor Green
    Write-Host "  Verificando en DynamoDB..." -ForegroundColor Gray
    
    Start-Sleep -Seconds 2
    $dbOrders = aws dynamodb scan --table-name ucehub-cafeteria-orders-qa --max-items 1 | ConvertFrom-Json
    if ($dbOrders.Count -gt 0) {
        Write-Host "  ✓ Datos guardados en DynamoDB" -ForegroundColor Green
    } else {
        Write-Host "  ✗ No se encontraron datos en DynamoDB" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Error creando orden: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

# 4. Test API Support Ticket
Write-Host "`n4. Probando API de Soporte..." -ForegroundColor Yellow
try {
    $ticketData = @{
        category = "Tecnico"
        priority = "Media"
        subject = "Test"
        description = "Ticket de prueba"
        userEmail = "test@uce.edu.ec"
        userName = "Usuario Test"
    } | ConvertTo-Json

    $ticket = Invoke-RestMethod -Uri "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/api/support/ticket" -Method Post -Body $ticketData -ContentType "application/json"
    Write-Host "✓ Ticket creado: $($ticket.data.ticketId)" -ForegroundColor Green
} catch {
    Write-Host "✗ Error creando ticket: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

# 5. Verificar instancias
Write-Host "`n5. Verificando instancias EC2..." -ForegroundColor Yellow
$instances = aws ec2 describe-instances --filters "Name=tag:Name,Values=ucehub-app-server-qa" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress]" --output text
if ($instances) {
    Write-Host "✓ Instancias en ejecución:" -ForegroundColor Green
    Write-Host $instances -ForegroundColor Gray
} else {
    Write-Host "✗ No hay instancias en ejecución" -ForegroundColor Red
}

# 6. Verificar target group health
Write-Host "`n6. Verificando Target Group..." -ForegroundColor Yellow
$tgArn = aws elbv2 describe-target-groups --names ucehub-tg-qa --query "TargetGroups[0].TargetGroupArn" --output text
$targetHealth = aws elbv2 describe-target-health --target-group-arn $tgArn | ConvertFrom-Json
foreach ($target in $targetHealth.TargetHealthDescriptions) {
    $state = $target.TargetHealth.State
    $color = if ($state -eq "healthy") { "Green" } else { "Red" }
    Write-Host "  Target $($target.Target.Id): $state" -ForegroundColor $color
    if ($target.TargetHealth.Reason) {
        Write-Host "    Reason: $($target.TargetHealth.Reason)" -ForegroundColor Yellow
    }
}

Write-Host "`n=== FIN DIAGNOSTICO ===" -ForegroundColor Cyan
