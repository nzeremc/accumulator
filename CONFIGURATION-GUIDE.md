# Configuration Guide - Where to Put Your Information

This guide shows you exactly where to configure your specific values for the DOCMP infrastructure.

---

## 📍 Configuration Locations

### 1. Terraform State Bucket (S3)

**Your Value**: `docmp-terraform-state-2101`

**Where to Put It**:

#### A. GitHub Secret (For GitHub Actions)
1. Go to GitHub Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `TF_STATE_BUCKET`
4. Value: `docmp-terraform-state-2101`
5. Click "Add secret"

#### B. Local Terraform Init (For Local Deployment)
```bash
terraform init \
  -backend-config="bucket=docmp-terraform-state-2101" \
  -backend-config="key=docmp/terraform.tfstate" \
  -backend-config="region=ap-south-1"
```

---

### 2. AWS Region

**Your Value**: `ap-south-1` (Mumbai)

**Where to Put It**:

#### A. terraform.tfvars (Main Configuration File)
```hcl
aws_region = "ap-south-1"
```
✅ Already configured in your `terraform.tfvars` file

#### B. GitHub Secret (For GitHub Actions)
1. Go to GitHub Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `AWS_REGION`
4. Value: `ap-south-1`
5. Click "Add secret"

#### C. Availability Zones (Must Match Region)
In `terraform.tfvars`:
```hcl
availability_zones = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
```
✅ Already configured in your `terraform.tfvars` file

---

## 📝 Complete Configuration Checklist

### File: `terraform.tfvars` (Main Configuration)

This file contains ALL your infrastructure configuration. Here's what you need to update:

```hcl
# ============================================
# 1. REGION CONFIGURATION
# ============================================
aws_region = "ap-south-1"  ✅ Already set
availability_zones = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]  ✅ Already set

# ============================================
# 2. DATABASE PASSWORD (REQUIRED - CHANGE THIS!)
# ============================================
rds_master_password = "CHANGE_THIS_TO_SECURE_PASSWORD_123!"  ⚠️ CHANGE THIS!
# Requirements:
# - Minimum 16 characters
# - Include uppercase, lowercase, numbers, special characters
# - Don't use common words

# ============================================
# 3. S3 BUCKET FOR DATA (REQUIRED - MUST BE UNIQUE)
# ============================================
s3_bucket_name = "docmp-data-testing-2101"  ⚠️ UPDATE IF NEEDED
# This is different from the state bucket
# Must be globally unique across all AWS accounts

# ============================================
# 4. ECR REPOSITORY URI (REQUIRED - UPDATE AFTER CREATING ECR)
# ============================================
ecs_container_image = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/docmp-app:latest"  ⚠️ UPDATE THIS!
# Replace 123456789012 with your AWS account ID
# Get this from: AWS Console → ECR → Repositories → docmp-app → Copy URI
```

---

## 🔐 GitHub Secrets Configuration

You need to configure these 6 secrets in GitHub:

### How to Add Secrets:
1. Go to your GitHub repository
2. Click **Settings** tab
3. In left sidebar: **Secrets and variables** → **Actions**
4. Click **New repository secret** for each

### Required Secrets:

| Secret Name | Your Value | Where to Get It |
|-------------|------------|-----------------|
| `AWS_ACCESS_KEY_ID` | `AKIA...` | AWS Console → IAM → Users → terraform-docmp-user → Security credentials → Access keys |
| `AWS_SECRET_ACCESS_KEY` | `wJalr...` | Same as above (shown only once when created) |
| `AWS_REGION` | `ap-south-1` | Your chosen region |
| `TF_STATE_BUCKET` | `docmp-terraform-state-2101` | Your S3 state bucket name |
| `ECR_REPOSITORY_NAME` | `docmp-app` | Your ECR repository name |
| `TF_VAR_rds_master_password` | `YourSecurePassword123!` | Your database password (optional, can use tfvars) |

---

## 📂 File Structure Overview

```
aws-tf/
├── terraform.tfvars              ⭐ YOUR MAIN CONFIG FILE (edit this)
├── terraform.tfvars.example      📄 Template (don't edit)
├── provider.tf                   🔧 Provider config (no changes needed)
├── main.tf                       🔧 Root module (no changes needed)
├── variables.tf                  🔧 Variable definitions (no changes needed)
└── outputs.tf                    🔧 Outputs (no changes needed)
```

**Only edit**: `terraform.tfvars`

---

## 🎯 Quick Configuration Steps

### Step 1: Update terraform.tfvars

Open `terraform.tfvars` and update these 3 values:

```hcl
# 1. Database password (REQUIRED)
rds_master_password = "YourSecurePassword123!"

# 2. S3 data bucket (REQUIRED - must be globally unique)
s3_bucket_name = "docmp-data-testing-2101"

# 3. ECR container image (REQUIRED - update after creating ECR)
ecs_container_image = "YOUR_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/docmp-app:latest"
```

### Step 2: Configure GitHub Secrets

Add these 6 secrets in GitHub:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION = `ap-south-1`
- TF_STATE_BUCKET = `docmp-terraform-state-2101`
- ECR_REPOSITORY_NAME = `docmp-app`
- TF_VAR_rds_master_password (optional)

### Step 3: Initialize Terraform (Local Deployment)

```bash
terraform init \
  -backend-config="bucket=docmp-terraform-state-2101" \
  -backend-config="key=docmp/terraform.tfstate" \
  -backend-config="region=ap-south-1"
```

### Step 4: Deploy

**Via GitHub Actions:**
```bash
git add terraform.tfvars
git commit -m "Configure for ap-south-1 region"
git push origin main
```

**Via Local Terraform:**
```bash
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

---

## 🔄 For Client to Change Configuration

When your client needs to change the configuration:

### 1. Change Region

Edit `terraform.tfvars`:
```hcl
aws_region = "us-east-1"  # Change to their region
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]  # Update AZs
```

Also update in GitHub Secret:
- `AWS_REGION` = `us-east-1`

And in Terraform init:
```bash
terraform init \
  -backend-config="bucket=their-state-bucket" \
  -backend-config="region=us-east-1"
```

### 2. Change Instance Sizes

Edit `terraform.tfvars`:
```hcl
rds_instance_class = "db.t3.xlarge"  # Larger instance
msk_instance_type = "kafka.m5.xlarge"  # Larger brokers
redis_node_type = "cache.t3.large"  # Larger cache
ecs_task_cpu = "2048"  # More CPU
ecs_task_memory = "4096"  # More memory
```

### 3. Change Resource Counts

Edit `terraform.tfvars`:
```hcl
msk_number_of_broker_nodes = 5  # More Kafka brokers
redis_num_cache_nodes = 3  # More Redis nodes
ecs_desired_count = 4  # More ECS tasks
```

### 4. Change Passwords/Credentials

Edit `terraform.tfvars`:
```hcl
rds_master_password = "NewSecurePassword123!"
rds_master_username = "new_admin"
```

Or use GitHub Secret:
- `TF_VAR_rds_master_password` = `NewSecurePassword123!`

---

## 📋 Configuration Validation

Before deploying, verify:

### terraform.tfvars
- [ ] `aws_region` = `ap-south-1`
- [ ] `availability_zones` match the region
- [ ] `rds_master_password` is strong (16+ chars)
- [ ] `s3_bucket_name` is globally unique
- [ ] `ecs_container_image` has correct ECR URI

### GitHub Secrets
- [ ] `AWS_ACCESS_KEY_ID` is set
- [ ] `AWS_SECRET_ACCESS_KEY` is set
- [ ] `AWS_REGION` = `ap-south-1`
- [ ] `TF_STATE_BUCKET` = `docmp-terraform-state-2101`
- [ ] `ECR_REPOSITORY_NAME` = `docmp-app`

### AWS Resources Created
- [ ] S3 bucket: `docmp-terraform-state-2101` exists
- [ ] ECR repository: `docmp-app` exists
- [ ] ECR repository: `docmp-app-db-init` exists
- [ ] IAM user: `terraform-docmp-user` exists with policy

---

## 🎯 Summary

### Your Current Configuration:

| Setting | Value |
|---------|-------|
| **Region** | ap-south-1 (Mumbai) |
| **State Bucket** | docmp-terraform-state-2101 |
| **Availability Zones** | ap-south-1a, ap-south-1b, ap-south-1c |
| **Environment** | testing |
| **Data Bucket** | docmp-data-testing-2101 |

### Files to Edit:
1. ✅ `terraform.tfvars` - Main configuration (already created for you)
2. ⚠️ Update 3 values in terraform.tfvars:
   - Database password
   - S3 data bucket name (if needed)
   - ECR container image URI

### GitHub Secrets to Configure:
1. AWS_ACCESS_KEY_ID
2. AWS_SECRET_ACCESS_KEY
3. AWS_REGION = `ap-south-1`
4. TF_STATE_BUCKET = `docmp-terraform-state-2101`
5. ECR_REPOSITORY_NAME = `docmp-app`
6. TF_VAR_rds_master_password (optional)

---

## 🚀 Ready to Deploy?

1. **Update** `terraform.tfvars` (3 values)
2. **Configure** GitHub Secrets (6 secrets)
3. **Push** to GitHub or run `terraform apply`

That's it! Everything else is automated.

---

## 📞 Need Help?

- **Configuration issues**: Check this file
- **Deployment issues**: See DEPLOYMENT.md
- **AWS setup**: See AWS-CONSOLE-SETUP.md
- **Quick start**: See QUICKSTART.md