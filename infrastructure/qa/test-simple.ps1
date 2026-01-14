# Test UCEHub APIs

Write-Host "=== TEST UCEHUB ===" -ForegroundColor Cyan

# Test crear orden
Write-Host "`nCreando orden de prueba..." -ForegroundColor Yellow
$body = @{
    items = @(@{ id=1; name="Cafe"; price=1.50; quantity=2 })
    total = 3.00
    userEmail = "test@uce.edu.ec"
    userName = "Test User"
    paymentMethod = "Efectivo"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/api/cafeteria/order" -Method Post -Body $body -ContentType "application/json"
    Write-Host "Orden creada: $($response.data.orderId)" -ForegroundColor Green
    
    Write-Host "`nVerificando en DynamoDB..." -ForegroundColor Yellow
    aws dynamodb scan --table-name ucehub-cafeteria-orders-qa --max-items 5
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ErrorDetails.Message -ForegroundColor Red
}
