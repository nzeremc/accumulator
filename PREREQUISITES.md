# Prerequisites and Setup Guide

This document outlines all prerequisites needed before deploying the DOCMP infrastructure.

---

## 1. AWS Account Setup

### 1.1 Create AWS Account
- Sign up at https://aws.amazon.com if you don't have an account
- Complete account verification
- Set up billing alerts

### 1.2 Create IAM User for Terraform/GitHub Actions

#### Step 1: Create the User

```bash
aws iam create-user --user-name terraform-docmp-user
```

#### Step 2: Create IAM Policy

Create a file named `terraform-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "rds:*",
        "kafka:*",
        "elasticache:*",
        "ecs:*",
        "ecr:*",
        "s3:*",
        "iam:*",
        "logs:*",
        "cloudwatch:*",
        "secretsmanager:*",
        "kms:*",
        "application-autoscaling:*",
        "route53:*",
        "acm:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Step 3: Create and Attach Policy

```bash
# Create the policy
aws iam create-policy \
  --policy-name TerraformDOCMPPolicy \
  --policy-document file://terraform-policy.json

# Attach policy to user (replace ACCOUNT_ID with your AWS account ID)
aws iam attach-user-policy \
  --user-name terraform-docmp-user \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/TerraformDOCMPPolicy
```

#### Step 4: Create Access Keys

```bash
aws iam create-access-key --user-name terraform-docmp-user
```

**Save the output:**
```json
{
    "AccessKey": {
        "UserName": "terraform-docmp-user",
        "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
        "Status": "Active",
        "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        "CreateDate": "2024-01-01T00:00:00Z"
    }
}
```

⚠️ **IMPORTANT**: Save these credentials securely. You'll need them for GitHub Secrets.

---

## 2. S3 Bucket for Terraform State

### Create State Bucket

```bash
# Create bucket (use a unique name)
aws s3 mb s3://docmp-terraform-state-YOUR-UNIQUE-ID --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket docmp-terraform-state-YOUR-UNIQUE-ID \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket docmp-terraform-state-YOUR-UNIQUE-ID \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket docmp-terraform-state-YOUR-UNIQUE-ID \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

---

## 3. ECR Repositories

### Create Repositories for Container Images

```bash
# Create repository for application
aws ecr create-repository \
  --repository-name docmp-app \
  --region us-east-1 \
  --image-scanning-configuration scanOnPush=true

# Create repository for DB initialization
aws ecr create-repository \
  --repository-name docmp-app-db-init \
  --region us-east-1 \
  --image-scanning-configuration scanOnPush=true
```

**Save the repository URIs** (you'll need them for terraform.tfvars):
```
123456789012.dkr.ecr.us-east-1.amazonaws.com/docmp-app
123456789012.dkr.ecr.us-east-1.amazonaws.com/docmp-app-db-init
```

---

## 4. GitHub Repository Setup

### 4.1 Create GitHub Repository

1. Go to https://github.com/new
2. Create a new repository named `docmp-infrastructure`
3. Keep it private
4. Don't initialize with README (we already have one)

### 4.2 Configure GitHub Secrets

Go to: **Repository → Settings → Secrets and variables → Actions → New repository secret**

Add these secrets:

| Secret Name | Value | Where to Get It |
|-------------|-------|-----------------|
| `AWS_ACCESS_KEY_ID` | `AKIAIOSFODNN7EXAMPLE` | From Step 1.2.4 above |
| `AWS_SECRET_ACCESS_KEY` | `wJalrXUtnFEMI/K7MDENG...` | From Step 1.2.4 above |
| `AWS_REGION` | `us-east-1` | Your chosen AWS region |
| `TF_STATE_BUCKET` | `docmp-terraform-state-YOUR-UNIQUE-ID` | From Step 2 above |
| `ECR_REPOSITORY_NAME` | `docmp-app` | From Step 3 above |

### 4.3 Push Code to GitHub

```bash
# Initialize git (if not already done)
git init

# Add remote
git remote add origin https://github.com/YOUR-USERNAME/docmp-infrastructure.git

# Add all files
git add .

# Commit
git commit -m "Initial commit: DOCMP infrastructure"

# Push to main branch
git branch -M main
git push -u origin main
```

---

## 5. Configure terraform.tfvars

### 5.1 Copy Example File

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 5.2 Edit terraform.tfvars

**IMPORTANT**: Update these values:

```hcl
# General Configuration
aws_region   = "us-east-1"  # Your AWS region
project_name = "docmp"
environment  = "production"

# Networking Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]  # Update for your region
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# RDS PostgreSQL Configuration
rds_instance_class          = "db.t3.large"
rds_allocated_storage       = 100
rds_engine_version          = "15.4"
rds_database_name           = "docmp"
rds_master_username         = "docmp_admin"
rds_master_password         = "CHANGE_TO_STRONG_PASSWORD_HERE"  # ⚠️ CHANGE THIS!
rds_backup_retention_period = 7
rds_multi_az                = true

# MSK (Kafka) Configuration
msk_instance_type          = "kafka.m5.large"
msk_number_of_broker_nodes = 3
msk_kafka_version          = "3.5.1"
msk_ebs_volume_size        = 100

# Redis Configuration
redis_node_type              = "cache.t3.medium"
redis_num_cache_nodes        = 2
redis_engine_version         = "7.0"
redis_parameter_group_family = "redis7"

# ECS Configuration
ecs_task_cpu        = "1024"
ecs_task_memory     = "2048"
ecs_desired_count   = 2
ecs_container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/docmp-app:latest"  # ⚠️ UPDATE THIS!
ecs_container_port  = 8080

# Database Initialization Configuration
db_init_script_s3_key       = "init/schema.sql"
db_init_static_files_prefix = "static-data/"
enable_db_initialization    = true

# Load Balancer Configuration
alb_health_check_path     = "/health"
alb_health_check_interval = 30
alb_health_check_timeout  = 5
alb_healthy_threshold     = 2
alb_unhealthy_threshold   = 3

# S3 Configuration
s3_bucket_name        = "docmp-data-YOUR-UNIQUE-ID"  # ⚠️ MUST BE GLOBALLY UNIQUE!
s3_versioning_enabled = true

# Additional Tags
additional_tags = {
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
  Compliance  = "HIPAA"
}
```

### 5.3 Secure terraform.tfvars

**Option 1: Don't commit to Git (Recommended)**
```bash
# terraform.tfvars is already in .gitignore
# Store it securely (password manager, encrypted storage)
```

**Option 2: Use GitHub Secrets for Sensitive Values**

Instead of hardcoding passwords in terraform.tfvars, you can:

1. Add secrets to GitHub:
   - `TF_VAR_rds_master_password`
   - `TF_VAR_s3_bucket_name`

2. Update GitHub Actions workflow to use them:
```yaml
env:
  TF_VAR_rds_master_password: ${{ secrets.TF_VAR_rds_master_password }}
  TF_VAR_s3_bucket_name: ${{ secrets.TF_VAR_s3_bucket_name }}
```

---

## 6. Prepare Database Files

### 6.1 Create SQL Schema

```bash
# Copy example
cp scripts/schema.sql.example scripts/schema.sql

# Edit with your actual schema
nano scripts/schema.sql
```

### 6.2 Prepare Static Data Files

Create CSV files for static data:

**Example: countries.csv**
```csv
code,name,is_active
USA,United States,true
CAN,Canada,true
GBR,United Kingdom,true
IND,India,true
```

**Example: categories.csv**
```csv
code,name,parent_id,is_active
TECH,Technology,,true
SOFT,Software,1,true
HARD,Hardware,1,true
```

---

## 7. Install Required Tools

### 7.1 Terraform

**macOS:**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Linux:**
```bash
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

**Windows:**
Download from https://www.terraform.io/downloads

**Verify:**
```bash
terraform version
```

### 7.2 AWS CLI

**macOS:**
```bash
brew install awscli
```

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Windows:**
Download from https://aws.amazon.com/cli/

**Configure:**
```bash
aws configure
# Enter your Access Key ID
# Enter your Secret Access Key
# Enter default region: us-east-1
# Enter default output format: json
```

**Verify:**
```bash
aws sts get-caller-identity
```

### 7.3 Docker

Download and install from https://www.docker.com/products/docker-desktop

**Verify:**
```bash
docker --version
```

### 7.4 Git

**macOS:**
```bash
brew install git
```

**Linux:**
```bash
sudo apt-get install git  # Ubuntu/Debian
sudo yum install git      # CentOS/RHEL
```

**Windows:**
Download from https://git-scm.com/download/win

**Verify:**
```bash
git --version
```

---

## 8. Pre-Deployment Checklist

Before running Terraform, verify:

- [ ] AWS account created and verified
- [ ] IAM user created with proper policy
- [ ] Access keys generated and saved
- [ ] S3 bucket created for Terraform state
- [ ] ECR repositories created
- [ ] GitHub repository created
- [ ] GitHub secrets configured
- [ ] terraform.tfvars file created and customized
- [ ] Strong password set for RDS
- [ ] Unique S3 bucket name chosen
- [ ] ECR repository URLs updated in terraform.tfvars
- [ ] SQL schema file prepared
- [ ] Static data CSV files prepared
- [ ] Terraform installed
- [ ] AWS CLI installed and configured
- [ ] Docker installed
- [ ] Git installed

---

## 9. Cost Estimation

Approximate monthly costs (us-east-1):

| Service | Configuration | Estimated Cost |
|---------|--------------|----------------|
| RDS PostgreSQL (2 instances) | db.t3.large, 100GB | ~$200 |
| MSK (Kafka) | 3 x kafka.m5.large | ~$600 |
| ElastiCache (Redis) | 2 x cache.t3.medium | ~$100 |
| ECS Fargate | 2 tasks, 1 vCPU, 2GB | ~$60 |
| Application Load Balancer | Standard | ~$25 |
| NAT Gateway | 3 AZs | ~$100 |
| Data Transfer | Moderate | ~$50 |
| CloudWatch Logs | 7 days retention | ~$10 |
| **Total** | | **~$1,145/month** |

**Cost Optimization Tips:**
- Use smaller instance types for non-production
- Reduce number of AZs to 2
- Use single NAT Gateway
- Reduce MSK broker count to 2
- Use Reserved Instances for long-term

---

## 10. Security Best Practices

### 10.1 Enable MFA on AWS Root Account

1. Go to AWS Console → IAM → Dashboard
2. Enable MFA for root account
3. Use authenticator app (Google Authenticator, Authy)

### 10.2 Enable CloudTrail

```bash
aws cloudtrail create-trail \
  --name docmp-trail \
  --s3-bucket-name docmp-cloudtrail-logs

aws cloudtrail start-logging --name docmp-trail
```

### 10.3 Enable AWS Config

```bash
aws configservice put-configuration-recorder \
  --configuration-recorder name=default,roleARN=arn:aws:iam::ACCOUNT_ID:role/config-role

aws configservice put-delivery-channel \
  --delivery-channel name=default,s3BucketName=docmp-config-logs
```

### 10.4 Password Policy

- Minimum 16 characters
- Include uppercase, lowercase, numbers, symbols
- Use password manager
- Rotate every 90 days
- Never commit to Git

---

## 11. Next Steps

After completing all prerequisites:

1. Review DEPLOYMENT.md for deployment steps
2. Test locally with `terraform plan`
3. Deploy via GitHub Actions or locally
4. Follow post-deployment configuration in DEPLOYMENT.md
5. Set up monitoring and alerting
6. Configure backups and disaster recovery

---

## 12. Support and Resources

- **Terraform Documentation**: https://www.terraform.io/docs
- **AWS Documentation**: https://docs.aws.amazon.com
- **GitHub Actions**: https://docs.github.com/en/actions
- **Project README**: See README.md in this repository
- **Deployment Guide**: See DEPLOYMENT.md in this repository

---

## Troubleshooting Common Issues

### Issue: AWS CLI not configured
```bash
aws configure
# Enter credentials from Step 1.2.4
```

### Issue: Terraform state bucket doesn't exist
```bash
# Create it following Step 2
```

### Issue: ECR repository not found
```bash
# Create it following Step 3
```

### Issue: GitHub Actions failing
- Check GitHub Secrets are set correctly
- Verify AWS credentials have proper permissions
- Check CloudWatch Logs for detailed errors

---

**Ready to Deploy?** Proceed to DEPLOYMENT.md