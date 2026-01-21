# ========================================
# UCEHub Complete Deployment Script
# Deploys infrastructure, APIs, and frontend
# ========================================

param(
    [string]$Environment = "qa",
    [string]$AWSRegion = "us-east-1",
    [switch]$SkipInfra,
    [switch]$SkipApis,
    [switch]$SkipFrontend,
    [switch]$TestOnly,
    [switch]$CleanupOnly
)

$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent -Path $ScriptRoot

# Color outputs
function Write-Success { Write-Host $args[0] -ForegroundColor Green }
function Write-Info { Write-Host $args[0] -ForegroundColor Cyan }
function Write-Warn { Write-Host $args[0] -ForegroundColor Yellow }
function Write-Error { Write-Host $args[0] -ForegroundColor Red }

Write-Info "=========================================="
Write-Info "UCEHub Complete Deployment"
Write-Info "=========================================="
Write-Info "Environment: $Environment"
Write-Info "Region: $AWSRegion"
Write-Info "Skip Infrastructure: $SkipInfra"
Write-Info "Skip APIs: $SkipApis"
Write-Info "Skip Frontend: $SkipFrontend"

# Verify prerequisites
Write-Info "`nVerifying prerequisites..."
$tools = @("terraform", "aws", "docker", "node", "npm")
$missingTools = @()

foreach ($tool in $tools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Success "✓ $tool"
    } else {
        Write-Warn "✗ $tool (optional)"
        $missingTools += $tool
    }
}

# Verify AWS credentials
Write-Info "`nVerifying AWS credentials..."
try {
    $identity = (aws sts get-caller-identity --region $AWSRegion | ConvertFrom-Json)
    Write-Success "✓ AWS Account: $($identity.Account)"
} catch {
    Write-Error "✗ AWS credentials failed. Configure with: aws configure"
    exit 1
}

# Cleanup phase
if ($CleanupOnly) {
    Write-Warn "`nCleaning up infrastructure..."
    $confirm = Read-Host "Type 'destroy' to confirm infrastructure destruction"
    if ($confirm -eq "destroy") {
        Push-Location "$ProjectRoot\infrastructure\$Environment"
        try {
            terraform destroy
            Write-Success "✓ Infrastructure destroyed"
        } catch {
            Write-Error "✗ Destroy failed: $_"
        }
        Pop-Location
    } else {
        Write-Warn "Cleanup cancelled"
    }
    exit 0
}

# ========================================
# Phase 1: Infrastructure Deployment
# ========================================

if (!$SkipInfra -and !$TestOnly) {
    Write-Info "`n========================================`n"
    Write-Info "Phase 1: Infrastructure Deployment"
    Write-Info "========================================`n"
    
    Push-Location "$ProjectRoot\infrastructure\$Environment"
    
    try {
        Write-Info "Initializing Terraform..."
        terraform init -upgrade
        Write-Success "✓ Terraform initialized"
        
        Write-Info "`nValidating configuration..."
        terraform validate
        Write-Success "✓ Configuration valid"
        
        Write-Info "`nPlanning deployment..."
        terraform plan -out=tfplan -var-file="terraform.tfvars"
        
        $response = Read-Host "`nApply infrastructure changes? (yes/no)"
        if ($response -eq "yes") {
            Write-Info "Applying infrastructure..."
            terraform apply tfplan
            Write-Success "✓ Infrastructure deployed"
            
            # Save outputs
            $outputs = terraform output -json | ConvertFrom-Json
            Write-Info "Retrieving deployment outputs..."
            
            if ($outputs.alb_dns_name) {
                $albDns = $outputs.alb_dns_name.value
                Write-Success "✓ ALB DNS: http://$albDns"
                
                # Save for later use
                $albDns | Out-File -FilePath ".alb_dns" -Encoding UTF8
            }
            
            # Save full outputs
            terraform output -json | Out-File -FilePath "outputs.json" -Encoding UTF8
            Write-Success "✓ Outputs saved to outputs.json"
        } else {
            Write-Warn "Infrastructure deployment cancelled"
        }
        
    } catch {
        Write-Error "Infrastructure deployment failed: $_"
        Pop-Location
        exit 1
    }
    
    Pop-Location
}

# ========================================
# Phase 2: API Validation
# ========================================

if (!$SkipApis) {
    Write-Info "`n========================================`n"
    Write-Info "Phase 2: API Validation"
    Write-Info "========================================`n"
    
    # Get ALB endpoint
    $albDnsFile = "$ProjectRoot\infrastructure\$Environment\.alb_dns"
    $albDns = if (Test-Path $albDnsFile) {
        Get-Content $albDnsFile -Raw
    } else {
        "ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com"
    }
    
    $apiUrl = "http://$albDns"
    Write-Info "Testing API at: $apiUrl"
    
    # Wait for ALB to be ready
    Write-Info "`nWaiting for ALB to be ready (this may take 2-3 minutes)..."
    $maxRetries = 30
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries) {
        try {
            $response = Invoke-WebRequest -Uri "$apiUrl/health" -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Success "✓ API is ready"
                break
            }
        } catch {
            # API not ready yet
        }
        
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Info "  Attempt $retryCount/$maxRetries - Waiting..."
            Start-Sleep -Seconds 10
        }
    }
    
    if ($retryCount -eq $maxRetries) {
        Write-Warn "⚠ API health check timeout - It may still be starting"
    } else {
        Write-Success "✓ API is responding"
        
        # Test health endpoint
        try {
            $health = Invoke-WebRequest -Uri "$apiUrl/health" | ConvertFrom-Json
            Write-Success "✓ Health Status: $($health.status)"
            Write-Info "  Service: $($health.service)"
            Write-Info "  Cafeteria Table: $($health.config.cafeteria_table)"
            Write-Info "  Support Table: $($health.config.support_table)"
            Write-Info "  Justifications Table: $($health.config.justifications_table)"
            Write-Info "  Teams Webhook: $($health.config.teams_webhook_configured)"
        } catch {
            Write-Warn "⚠ Could not retrieve full health information"
        }
    }
}

# ========================================
# Phase 3: Frontend Build
# ========================================

if (!$SkipFrontend) {
    Write-Info "`n========================================`n"
    Write-Info "Phase 3: Frontend Build"
    Write-Info "========================================`n"
    
    Push-Location "$ProjectRoot\teams-app"
    
    try {
        Write-Info "Installing frontend dependencies..."
        npm ci
        Write-Success "✓ Dependencies installed"
        
        # Get ALB DNS and set environment variables
        $albDnsFile = "$ProjectRoot\infrastructure\$Environment\.alb_dns"
        if (Test-Path $albDnsFile) {
            $albDns = Get-Content $albDnsFile -Raw
            $env:VITE_API_URL = "http://$albDns"
            $env:VITE_BACKEND_URL = "http://$albDns"
            Write-Info "✓ API URL set to: http://$albDns"
        }
        
        Write-Info "`nBuilding frontend..."
        npm run build
        Write-Success "✓ Frontend built successfully"
        
        $distSize = (Get-ChildItem "dist" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
        Write-Info "✓ Distribution size: $([Math]::Round($distSize, 2)) MB"
        
    } catch {
        Write-Error "Frontend build failed: $_"
        Pop-Location
        exit 1
    }
    
    Pop-Location
}

# ========================================
# Summary
# ========================================

Write-Success "`n========================================`n"
Write-Success "Deployment completed successfully!"
Write-Success "========================================`n"

Write-Info "Next steps:"
if (!$SkipInfra) {
    Write-Info "1. Infrastructure deployed to AWS"
}
Write-Info "2. Check infrastructure at: AWS Console"
Write-Info "3. Test APIs using: .\scripts\test-apis.ps1"
Write-Info "4. View logs: aws logs tail /aws/ec2/ucehub --follow"

if (!$SkipFrontend) {
    Write-Info "5. Frontend ready to upload to S3"
}

Write-Success "`nDeployment script completed successfully!"
