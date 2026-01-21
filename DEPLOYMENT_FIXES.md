# UCEHub - Deployment and Fixes Summary

## Issues Fixed

### 1. **API Endpoint Inconsistencies** ✓
- **Problem**: Frontend expected `/api/justifications/submit` but backend had `/justifications/submit`
- **Fixed**: 
  - Updated backend to use consistent endpoints: `/justifications/submit`, `/cafeteria/order`, `/support/ticket`
  - Updated frontend to use same paths
  - Added proper error logging to debug issues

### 2. **API URL Configuration** ✓
- **Problem**: Frontend wasn't connecting to the ALB endpoint
- **Fixed**:
  - Updated `CertificadosNew.tsx` to use ALB endpoint as fallback
  - Updated `SoporteNew.tsx` to use ALB endpoint
  - Updated `CafeteriaNew.tsx` to use ALB endpoint
  - Created `.env.qa` file with proper environment variables

### 3. **Error Handling and Logging** ✓
- **Problem**: Justifications submit endpoint lacked proper error handling
- **Fixed**:
  - Added validation for required fields
  - Added detailed error logging for S3 uploads
  - Added detailed error logging for DynamoDB operations
  - Added environment variable validation

### 4. **Frontend Build Configuration** ✓
- **Problem**: Frontend build wasn't picking up the API URL
- **Created**: `.env.qa` file with proper Vite environment variables
- **Variables**:
  ```
  VITE_API_URL=http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com
  VITE_BACKEND_URL=http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com
  NODE_ENV=production
  ```

---

## Files Modified/Created

### Modified Files:
1. **services/backend/server.js**
   - Enhanced `/justifications/submit` endpoint with better error handling
   - Added detailed logging for debugging
   - Added field validation
   - Fixed S3 error handling

2. **teams-app/src/pages/CertificadosNew.tsx**
   - Updated API_URL to use ALB endpoint

3. **teams-app/src/pages/SoporteNew.tsx**
   - Updated API_URL to use ALB endpoint

4. **teams-app/src/pages/CafeteriaNew.tsx**
   - Updated API_URL to use ALB endpoint
   - Fixed endpoint paths to be consistent

### New Files Created:
1. **teams-app/.env.qa** - Environment configuration for QA
2. **infrastructure/qa/deploy-full.ps1** - Complete deployment script
3. **infrastructure/deploy.sh** - Bash deployment helper
4. **scripts/build-teams-app.sh** - Frontend build script
5. **scripts/test-apis.sh** - API testing script
6. **deploy-all.ps1** - Master deployment orchestrator

---

## Deployment Instructions

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Node.js >= 18
- Docker (for local testing)
- PowerShell 5.1+ (for Windows scripts)

### Step 1: Verify Configuration

```bash
cd infrastructure/qa

# Check if terraform.tfvars exists
cat terraform.tfvars

# Make sure these values are set:
# - aws_region = "us-east-1"
# - project_name = "ucehub"
# - environment = "qa"
# - teams_webhook_url = "your-webhook-url"
```

### Step 2: Initialize and Validate Terraform

```bash
# Initialize Terraform
terraform init

# Format configuration
terraform fmt -recursive

# Validate configuration
terraform validate
```

### Step 3: Deploy Infrastructure

**Option A: Using Master Script (Recommended)**
```powershell
cd c:\Users\ASUS TUF A15\Desktop\TERRAFORM\terraform-infraestructura-como-codigo\3-infra-con-terraform\ucehub
.\deploy-all.ps1 -Environment qa
```

**Option B: Manual Terraform Deployment**
```bash
cd infrastructure/qa

# Create deployment plan
terraform plan -out=tfplan -var-file="terraform.tfvars"

# Review the plan and apply
terraform apply tfplan

# Get outputs
terraform output -json > outputs.json
terraform output -raw alb_dns_name > .alb_dns
```

### Step 4: Wait for Infrastructure to Be Ready

The ALB and EC2 instances may take 2-3 minutes to start. Monitor progress:

```bash
# Check ALB status
aws elb describe-load-balancers --region us-east-1 --query 'LoadBalancerDescriptions[].{Name:LoadBalancerName,State:SourceSecurityGroup}'

# Check EC2 instances
aws ec2 describe-instances --region us-east-1 --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,IP:PrivateIpAddress}'

# Check health
curl http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/health
```

### Step 5: Build and Deploy Frontend

```powershell
# Navigate to project root
cd C:\Users\ASUS TUF A15\Desktop\TERRAFORM\terraform-infraestructura-como-codigo\3-infra-con-terraform\ucehub

# Build frontend
cd teams-app
npm install
npm run build

# Optional: Upload to S3
# aws s3 sync dist/ s3://your-bucket-name/ --delete
```

### Step 6: Test APIs

```bash
# Using the test script
bash scripts/test-apis.sh qa http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com

# Or manually test individual endpoints
curl http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/health

# Test justifications endpoint
curl -X POST http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com/justifications/submit \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "Test User",
    "userEmail": "test@example.com",
    "reason": "Medical appointment",
    "startDate": "2024-01-25",
    "endDate": "2024-01-25"
  }'
```

---

## Troubleshooting

### Issue: "Error al enviar la justificación"

**Check 1: Verify DynamoDB Tables Exist**
```bash
aws dynamodb list-tables --region us-east-1 | grep absence
```

**Check 2: Verify IAM Permissions**
```bash
aws iam get-user
```

**Check 3: Check Backend Logs**
```bash
# SSH into EC2 instance
aws ssm start-session --target i-xxxxx --region us-east-1

# View container logs
docker logs $(docker ps -q | head -1)
```

**Check 4: Verify S3 Bucket Permissions**
```bash
aws s3api head-bucket --bucket ucehub-documents-qa-xxxxx
aws s3api get-bucket-acl --bucket ucehub-documents-qa-xxxxx
```

### Issue: API Not Responding

1. Check ALB status:
   ```bash
   aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...
   ```

2. Check EC2 instance health:
   ```bash
   aws ec2 describe-instance-status --instance-ids i-xxxxx --region us-east-1
   ```

3. Check security group rules:
   ```bash
   aws ec2 describe-security-groups --query 'SecurityGroups[?GroupName==`ucehub-alb-qa`]'
   ```

### Issue: Teams Webhook Not Working

1. Verify webhook URL in terraform.tfvars
2. Check Teams channel for proper configuration
3. Test webhook manually:
   ```bash
   curl -X POST "YOUR_WEBHOOK_URL" \
     -H "Content-Type: application/json" \
     -d '{"@type":"MessageCard","@context":"https://schema.org/extensions","summary":"Test","title":"Test","text":"This is a test"}'
   ```

---

## Environment Variables Reference

### Backend (EC2/Docker)
```bash
AWS_REGION=us-east-1
PROJECT_NAME=ucehub
ENVIRONMENT=qa
CAFETERIA_TABLE=ucehub-cafeteria-orders-qa
SUPPORT_TICKETS_TABLE=ucehub-support-tickets-qa
ABSENCE_JUSTIFICATIONS_TABLE=ucehub-absence-justifications-qa
DOCUMENTS_BUCKET=ucehub-documents-qa-xxxxx
TEAMS_WEBHOOK_URL=https://uceedu.webhook.office.com/...
PORT=3001
```

### Frontend (Vite)
```bash
VITE_API_URL=http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com
VITE_BACKEND_URL=http://ucehub-alb-qa-933851656.us-east-1.elb.amazonaws.com
NODE_ENV=production
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                  Internet / Teams                        │
└────────────────────────┬────────────────────────────────┘
                         │
                    ALB (ELB)
                         │
        ┌────────────────┴────────────────┐
        │                                 │
    ┌───┴────┐                       ┌───┴────┐
    │  EC2   │                       │  EC2   │
    │Instance│                       │Instance│
    │   #1   │                       │   #2   │
    └───┬────┘                       └───┬────┘
        │                               │
        │         Docker Container      │
        │    ┌────────────────────┐    │
        │    │ Express.js Server  │    │
        │    │  - /health         │    │
        │    │  - /justifications │    │
        │    │  - /cafeteria      │    │
        │    │  - /support        │    │
        │    └────────┬───────────┘    │
        │             │                 │
        └─────────────┼─────────────────┘
                      │
        ┌─────────────┼──────────────────┐
        │             │                  │
     DynamoDB      S3 Bucket         Teams
     - Cafeteria   - Documents       Webhook
     - Support
     - Justifications
```

---

## Scaling Architecture

The current setup is designed to be scalable:

1. **Auto Scaling Group**: Automatically scales from 1-5 EC2 instances based on CPU utilization
2. **DynamoDB**: On-demand billing scales automatically with traffic
3. **S3**: Unlimited capacity for documents
4. **ALB**: Distributes traffic across instances

### Performance Optimization Tips:

1. Reduce EC2 instance size if cost is a concern (currently t3.nano)
2. Use DynamoDB Global Secondary Indexes for faster queries
3. Implement caching layer (ElastiCache) for frequently accessed data
4. Enable CDN (CloudFront) for static frontend assets

---

## Cleanup (Destroy Resources)

To remove all resources and avoid costs:

```powershell
cd infrastructure\qa
terraform destroy
```

Or using the master script:
```powershell
.\deploy-all.ps1 -Environment qa -CleanupOnly
```

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Terraform/AWS logs
3. Check EC2 instance system logs via AWS Console
4. Review Docker container logs on the instances

