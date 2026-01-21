#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy UCEHub v3.0.1 - Correcciones Críticas
.DESCRIPTION
    Script para desplegar todos los cambios de la versión 3.0.1
.EXAMPLE
    .\deploy-fixes-v3.0.1.ps1 -Environment qa
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('qa', 'prod')]
    [string]$Environment = 'qa'
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "UCEHub Deploy v3.0.1" -ForegroundColor Green
Write-Host "Correcciones Críticas" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Git Commit
Write-Host "[1/5] Preparando cambios en Git..." -ForegroundColor Yellow
Push-Location $ScriptDir
$status = git status --porcelain

if ($status) {
    git add -A
    git commit -m "Deploy v3.0.1: Grafana, Cafeteria, Justificaciones, Soporte y Documentos"
    git push origin feature/prod-deployment
    Write-Host "✓ Cambios commiteados y pusheados" -ForegroundColor Green
} else {
    Write-Host "✓ Sin cambios pendientes" -ForegroundColor Green
}
Pop-Location

# 2. Construir Teams App
Write-Host "[2/5] Compilando Teams App..." -ForegroundColor Yellow
Push-Location "$ScriptDir/teams-app"
npm run build
Write-Host "✓ Teams App compilada exitosamente" -ForegroundColor Green
Pop-Location

# 3. Verificar Terraform
Write-Host "[3/5] Verificando Terraform..." -ForegroundColor Yellow
Push-Location "$ScriptDir/infrastructure/$Environment"

if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "✗ terraform.tfvars no encontrado" -ForegroundColor Red
    exit 1
}
Write-Host "✓ terraform.tfvars encontrado" -ForegroundColor Green

# 4. Plan Terraform
Write-Host "[4/5] Generando plan Terraform..." -ForegroundColor Yellow
terraform init
terraform plan -out=tfplan
Write-Host "✓ Plan generado" -ForegroundColor Green

# 5. Deploy Terraform
Write-Host "[5/5] Aplicando cambios Terraform..." -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANTE: Revisa el plan anterior antes de continuar" -ForegroundColor Yellow
Write-Host "Este paso desplegará la infraestructura en $Environment" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "¿Deseas continuar? (s/n)"

if ($confirm -ne "s") {
    Write-Host "Deploy cancelado" -ForegroundColor Yellow
    exit 0
}

terraform apply tfplan
Write-Host "✓ Cambios aplicados exitosamente" -ForegroundColor Green

# Resumen
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploy v3.0.1 COMPLETADO" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Lo siguiente:" -ForegroundColor Yellow
Write-Host "1. Verificar health check: terraform output -raw alb_dns_name" -ForegroundColor Cyan
Write-Host "2. Probar endpoints en Teams" -ForegroundColor Cyan
Write-Host "3. Validar Grafana URL" -ForegroundColor Cyan
Write-Host ""

Pop-Location
