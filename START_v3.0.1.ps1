#!/usr/bin/env pwsh
<#
.SYNOPSIS
    UCEHub v3.0.1 - Inicio Rápido
.DESCRIPTION
    Inicia el proceso de deploy de la versión 3.0.1 con correcciones críticas
.NOTES
    Ejecutar como: .\START_v3.0.1.ps1
#>

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   UCEHub v3.0.1 - Correcciones       ║" -ForegroundColor Cyan
Write-Host "║   Listo para Producción               ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Cambios en esta versión:" -ForegroundColor Yellow
Write-Host "   ✅ Grafana - URL de monitoreo funcional" -ForegroundColor Green
Write-Host "   ✅ Cafetería - Formulario de pago con datos" -ForegroundColor Green
Write-Host "   ✅ Justificaciones - Documentos completos en Teams" -ForegroundColor Green
Write-Host "   ✅ Soporte - Tickets con datos del usuario" -ForegroundColor Green
Write-Host "   ✅ Documentos - Descargas desde S3" -ForegroundColor Green
Write-Host ""

Write-Host "📚 Documentación disponible:" -ForegroundColor Yellow
Write-Host "   📄 RELEASE_NOTES_v3.0.1.md - Resumen ejecutivo" -ForegroundColor Cyan
Write-Host "   📄 FIXES_v3.0.1.md - Detalles técnicos" -ForegroundColor Cyan
Write-Host "   📄 TESTING_v3.0.1.md - Guía de testing" -ForegroundColor Cyan
Write-Host ""

Write-Host "🚀 Opciones de Deploy:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1️⃣  Deploy Automático (Recomendado)" -ForegroundColor Green
Write-Host "   .\deploy-fixes-v3.0.1.ps1 -Environment qa" -ForegroundColor Cyan
Write-Host ""
Write-Host "2️⃣  Deploy Manual" -ForegroundColor Green
Write-Host "   cd infrastructure/qa" -ForegroundColor Cyan
Write-Host "   terraform plan -out=tfplan" -ForegroundColor Cyan
Write-Host "   terraform apply tfplan" -ForegroundColor Cyan
Write-Host ""
Write-Host "3️⃣  Testing Local" -ForegroundColor Green
Write-Host "   cd teams-app" -ForegroundColor Cyan
Write-Host "   npm run dev" -ForegroundColor Cyan
Write-Host ""

$choice = Read-Host "Selecciona una opción (1/2/3) o presiona Ctrl+C para salir"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "Iniciando deploy automático..." -ForegroundColor Green
        & "$ScriptPath\deploy-fixes-v3.0.1.ps1" -Environment qa
    }
    "2" {
        Write-Host ""
        Write-Host "Iniciando deploy manual..." -ForegroundColor Green
        Push-Location "$ScriptPath\infrastructure\qa"
        terraform init
        terraform plan -out=tfplan
        terraform apply tfplan
        Pop-Location
    }
    "3" {
        Write-Host ""
        Write-Host "Iniciando testing local..." -ForegroundColor Green
        Push-Location "$ScriptPath\teams-app"
        npm run dev
        Pop-Location
    }
    default {
        Write-Host "Opción no válida" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "✅ Completado" -ForegroundColor Green
Write-Host ""
