#!/bin/bash
set -e

# ========================================
# UCEHub Quick Deployment Helper
# Automates common deployment tasks
# ========================================

ENVIRONMENT="${1:-qa}"
REGION="us-east-1"
PROJECT="ucehub"

function log_info() {
    echo -e "\033[36m[INFO]\033[0m $1"
}

function log_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

function log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
}

function log_warn() {
    echo -e "\033[33m[WARN]\033[0m $1"
}

# Check prerequisites
log_info "Checking prerequisites..."
for cmd in terraform aws docker; do
    if ! command -v $cmd &> /dev/null; then
        log_error "$cmd not found. Please install it first."
        exit 1
    fi
done
log_success "All prerequisites found"

# Check AWS credentials
log_info "Verifying AWS credentials..."
if ! aws sts get-caller-identity --region $REGION &>/dev/null; then
    log_error "AWS credentials not configured"
    exit 1
fi
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
log_success "AWS Account: $ACCOUNT"

# Navigate to infrastructure directory
cd infrastructure/$ENVIRONMENT

log_info "Environment: $ENVIRONMENT"
log_info "Region: $REGION"

# Initialize Terraform
log_info "Initializing Terraform..."
terraform init

# Format configuration
log_info "Formatting Terraform configuration..."
terraform fmt

# Validate configuration
log_info "Validating Terraform configuration..."
terraform validate
log_success "Configuration is valid"

# Plan deployment
log_info "Planning infrastructure changes..."
terraform plan -out=tfplan -var-file="terraform.tfvars"

# Show plan summary
CHANGES=$(terraform show -json tfplan | grep -c '"after"' || echo "0")
log_info "Planned changes: $CHANGES resources"

# Apply deployment
read -p "Apply changes to $ENVIRONMENT? (yes/no) " -n 3 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Applying infrastructure changes..."
    terraform apply tfplan
    log_success "Infrastructure deployed successfully"
    
    # Get outputs
    log_info "Retrieving deployment outputs..."
    terraform output -json > outputs.json
    
    ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "pending")
    log_success "ALB DNS: http://$ALB_DNS"
    
    # Save for later reference
    echo $ALB_DNS > .alb_dns
else
    log_warn "Deployment cancelled"
fi

log_success "Deployment script completed"
