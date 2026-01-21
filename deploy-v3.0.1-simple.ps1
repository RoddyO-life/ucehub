#!/usr/bin/env pwsh
# Deploy UCEHub v3.0.1 - Correcciones Criticas

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('qa', 'prod')]
    [string]$Environment = 'qa'
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "UCEHub Deploy v3.0.1" -ForegroundColor Green
Write-Host "Correcciones Criticas" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Git
Write-Host "[1/4] Git Commit & Push..." -ForegroundColor Yellow
Push-Location $ScriptDir
git add -A
$status = git status --porcelain
if ($status) {
    git commit -m "Deploy v3.0.1: Correcciones Criticas"
    git push origin feature/prod-deployment
    Write-Host "OK - Cambios pusheados" -ForegroundColor Green
} else {
    Write-Host "OK - Sin cambios nuevos" -ForegroundColor Green
}
Pop-Location
Write-Host ""

# 2. Build
Write-Host "[2/4] Build Teams App..." -ForegroundColor Yellow
Push-Location "$ScriptDir\teams-app"
npm run build 2>&1 | Out-Null
Write-Host "OK - Teams App compilada" -ForegroundColor Green
Pop-Location
Write-Host ""

# 3. Terraform Plan
Write-Host "[3/4] Terraform Plan..." -ForegroundColor Yellow
$TfDir = "$ScriptDir\infrastructure\$Environment"
Push-Location $TfDir
terraform init 2>&1 | Out-Null
terraform plan -out=tfplan
Write-Host "OK - Plan generado" -ForegroundColor Green
Write-Host ""

# 4. Confirmacion
Write-Host "[4/4] Aplicar cambios..." -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Continuar con deploy? (s/n)"
if ($confirm -eq "s") {
    terraform apply tfplan
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Deploy completado" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
} else {
    Write-Host "Cancelado" -ForegroundColor Yellow
}
Pop-Location
