# ========================================
# UCEHub Full Deployment Script
# Deploys all infrastructure and services
# ========================================

param(
    [string]$Environment = "qa",
    [switch]$Destroy,
    [switch]$RefreshOnly,
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$projectRoot = Split-Path -Parent -Path (Split-Path -Parent -Path $scriptDir)

Write-Host "========================================" -ForegroundColor Green
Write-Host "UCEHub Deployment Script" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor Cyan
$prerequisites = @("terraform", "aws", "docker")
foreach ($tool in $prerequisites) {
    $toolPath = Get-Command $tool -ErrorAction SilentlyContinue
    if ($toolPath) {
        Write-Host "✓ $tool found" -ForegroundColor Green
    } else {
        Write-Host "✗ $tool NOT found - Please install it first" -ForegroundColor Red
        exit 1
    }
}

# Verify AWS credentials
Write-Host "`nVerifying AWS credentials..." -ForegroundColor Cyan
try {
    $identity = aws sts get-caller-identity --region us-east-1 | ConvertFrom-Json
    Write-Host "✓ AWS Account: $($identity.Account)" -ForegroundColor Green
} catch {
    Write-Host "✗ AWS credentials not configured" -ForegroundColor Red
    exit 1
}

# Check terraform.tfvars
if (!(Test-Path "$scriptDir/terraform.tfvars")) {
    Write-Host "`n⚠ terraform.tfvars not found!" -ForegroundColor Yellow
    Write-Host "Creating from terraform.tfvars.example..." -ForegroundColor Yellow
    if (Test-Path "$scriptDir/terraform.tfvars.example") {
        Copy-Item "$scriptDir/terraform.tfvars.example" "$scriptDir/terraform.tfvars"
        Write-Host "✓ File created. Please update it with your configuration." -ForegroundColor Yellow
    }
}

# Initialize Terraform
if ($ValidateOnly -or !$Destroy -or !$RefreshOnly) {
    Write-Host "`n`nInitializing Terraform..." -ForegroundColor Cyan
    try {
        Push-Location $scriptDir
        terraform init
        Write-Host "✓ Terraform initialized" -ForegroundColor Green
    } catch {
        Write-Host "✗ Terraform init failed: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
}

# Validate configuration
if ($ValidateOnly) {
    Write-Host "`nValidating Terraform configuration..." -ForegroundColor Cyan
    try {
        Push-Location $scriptDir
        terraform validate
        Write-Host "✓ Configuration is valid" -ForegroundColor Green
        Pop-Location
        exit 0
    } catch {
        Write-Host "✗ Validation failed: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    }
}

# Refresh state
if ($RefreshOnly) {
    Write-Host "`nRefreshing Terraform state..." -ForegroundColor Cyan
    try {
        Push-Location $scriptDir
        terraform refresh
        Write-Host "✓ State refreshed" -ForegroundColor Green
        Pop-Location
        exit 0
    } catch {
        Write-Host "✗ Refresh failed: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    }
}

# Destroy infrastructure
if ($Destroy) {
    Write-Host "`n⚠⚠⚠ WARNING: About to DESTROY all resources! ⚠⚠⚠" -ForegroundColor Red
    $confirm = Read-Host "Type 'destroy' to confirm"
    if ($confirm -eq "destroy") {
        try {
            Push-Location $scriptDir
            terraform destroy
            Write-Host "✓ Infrastructure destroyed" -ForegroundColor Green
            Pop-Location
        } catch {
            Write-Host "✗ Destroy failed: $_" -ForegroundColor Red
            Pop-Location
            exit 1
        }
    } else {
        Write-Host "Destroy cancelled" -ForegroundColor Yellow
    }
    exit 0
}

# Plan deployment
Write-Host "`nPlanning infrastructure changes..." -ForegroundColor Cyan
try {
    Push-Location $scriptDir
    terraform plan -out=tfplan -var-file="terraform.tfvars"
    Write-Host "✓ Plan created (saved to tfplan)" -ForegroundColor Green
} catch {
    Write-Host "✗ Plan failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Apply deployment
Write-Host "`n⚠ About to deploy infrastructure" -ForegroundColor Yellow
$apply = Read-Host "Apply changes? (yes/no)"
if ($apply -eq "yes") {
    try {
        terraform apply tfplan
        Write-Host "✓ Infrastructure deployed successfully" -ForegroundColor Green
        
        # Get outputs
        Write-Host "`n========================================" -ForegroundColor Green
        Write-Host "Deployment Outputs:" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        
        $alb_dns = terraform output -raw alb_dns_name 2>/dev/null || "N/A"
        $instance_ips = terraform output -json instance_private_ips 2>/dev/null || "N/A"
        
        Write-Host "ALB DNS: $alb_dns" -ForegroundColor Cyan
        Write-Host "Instance IPs: $instance_ips" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Green
        
        # Save outputs to file
        terraform output -json > outputs.json
        Write-Host "✓ Outputs saved to outputs.json" -ForegroundColor Green
        
    } catch {
        Write-Host "✗ Apply failed: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    }
} else {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
}

Pop-Location

Write-Host "`n✓ Deployment script completed successfully!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Monitor resources in AWS Console" -ForegroundColor Cyan
Write-Host "2. Test APIs at: http://$alb_dns" -ForegroundColor Cyan
Write-Host "3. View logs: aws logs tail /aws/ec2/ucehub --follow" -ForegroundColor Cyan
