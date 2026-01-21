#!/usr/bin/env pwsh
# UCEHub Quick Start Script
# Execute this to deploy the entire infrastructure

param(
    [switch]$Validate,
    [switch]$Plan,
    [switch]$Apply,
    [switch]$All
)

$ErrorActionPreference = "Continue"
$InfraDir = "$PSScriptRoot\infrastructure\qa"

Write-Host "============================================" -ForegroundColor Green
Write-Host "UCEHub Infrastructure Setup" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

# Step 1: Initialize
Write-Host "`n[1/5] Initializing Terraform..." -ForegroundColor Cyan
Push-Location $InfraDir
terraform init
Pop-Location
Write-Host "✓ Terraform initialized" -ForegroundColor Green

# Step 2: Format
Write-Host "`n[2/5] Formatting configuration..." -ForegroundColor Cyan
Push-Location $InfraDir
terraform fmt -recursive
Pop-Location
Write-Host "✓ Configuration formatted" -ForegroundColor Green

# Step 3: Validate
if ($Validate -or $All) {
    Write-Host "`n[3/5] Validating configuration..." -ForegroundColor Cyan
    Push-Location $InfraDir
    terraform validate
    Pop-Location
    Write-Host "✓ Configuration is valid" -ForegroundColor Green
}

# Step 4: Plan
if ($Plan -or $All) {
    Write-Host "`n[4/5] Creating deployment plan..." -ForegroundColor Cyan
    Push-Location $InfraDir
    terraform plan -out=tfplan -var-file="terraform.tfvars"
    Pop-Location
    Write-Host "✓ Plan created (saved to tfplan)" -ForegroundColor Green
}

# Step 5: Apply
if ($Apply -or $All) {
    Write-Host "`n[5/5] Applying infrastructure..." -ForegroundColor Cyan
    Write-Host "⚠ This will create AWS resources and incur costs" -ForegroundColor Yellow
    
    $confirm = Read-Host "Continue? (yes/no)"
    if ($confirm -eq "yes") {
        Push-Location $InfraDir
        terraform apply tfplan
        
        Write-Host "`n✓ Infrastructure deployed successfully" -ForegroundColor Green
        
        # Get outputs
        Write-Host "`nDeployment Outputs:" -ForegroundColor Green
        terraform output -json | ConvertFrom-Json | ForEach-Object {
            $_ | Get-Member -MemberType NoteProperty | ForEach-Object {
                $key = $_.Name
                $value = $_.$key.value
                Write-Host "  $key = $value" -ForegroundColor Cyan
            }
        }
        
        Pop-Location
    } else {
        Write-Host "Deployment cancelled" -ForegroundColor Yellow
    }
}

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Wait 2-3 minutes for ALB and instances to start" -ForegroundColor Cyan
Write-Host "2. Build frontend: cd teams-app && npm run build" -ForegroundColor Cyan
Write-Host "3. Test APIs: bash scripts/test-apis.sh" -ForegroundColor Cyan
