# Quick Start Guide - DOCMP Infrastructure

This is a condensed guide to get you started quickly. For detailed information, see PREREQUISITES.md and DEPLOYMENT.md.

## 🚀 Quick Setup

### Step 1: AWS Prerequisites

Choose either **Manual Setup (AWS Console)** or **CLI Setup** below:

---

#### Option A: Manual Setup via AWS Console (Recommended for First-Time Users)

##### 1.1 Create IAM User

1. Go to AWS Console → IAM → Users → **Create user**
2. User name: `terraform-docmp-user`
3. Click **Next**
4. Select **Attach policies directly**
5. Click **Create policy** (opens new tab)

##### 1.2 Create IAM Policy

In the new tab:
1. Click **JSON** tab
2. Copy the entire content from `terraform-iam-policy.json` file in this repository
3. Paste it into the policy editor
4. Click **Next**
5. Policy name: `TerraformDOCMPPolicy`
6. Description: `Policy for Terraform to manage DOCMP infrastructure`
7. Click **Create policy**

##### 1.3 Attach Policy to User

Go back to the user creation tab:
1. Click the refresh button
2. Search for `TerraformDOCMPPolicy`
3. Check the box next to it
4. Click **Next**
5. Click **Create user**

##### 1.4 Create Access Keys

1. Click on the newly created user `terraform-docmp-user`
2. Go to **Security credentials** tab
3. Scroll to **Access keys** section
4. Click **Create access key**
5. Select **Command Line Interface (CLI)**
6. Check the confirmation box
7. Click **Next**
8. (Optional) Add description: `Terraform DOCMP deployment`
9. Click **Create access key**
10. **⚠️ IMPORTANT**: Click **Download .csv file** and save it securely
11. Copy the **Access key ID** and **Secret access key** - you'll need these for GitHub Secrets

##### 1.5 Create S3 Bucket for Terraform State

1. Go to AWS Console → S3 → **Create bucket**
2. Bucket name: `docmp-terraform-state-YOUR-UNIQUE-ID` (must be globally unique)
3. Region: `us-east-1` (or your preferred region)
4. **Block all public access**: Keep checked (default)
5. **Bucket Versioning**: Enable
6. **Default encryption**: Enable (SSE-S3)
7. Click **Create bucket**

##### 1.6 Create ECR Repositories

1. Go to AWS Console → ECR → **Create repository**
2. Repository name: `docmp-app`
3. **Scan on push**: Enable
4. Click **Create repository**
5. Repeat for second repository: `docmp-app-db-init`

**Save these repository URIs** (you'll need them later):
```
123456789012.dkr.ecr.us-east-1.amazonaws.com/docmp-app
123456789012.dkr.ecr.us-east-1.amazonaws.com/docmp-app-db-init
```

---

#### Option B: CLI Setup (For Advanced Users)

```bash
# 1. Create IAM user
aws iam create-user --user-name terraform-docmp-user

# 2. Create IAM policy
aws iam create-policy \
  --policy-name TerraformDOCMPPolicy \
  --policy-document file://terraform-iam-policy.json

# 3. Attach policy to user (replace ACCOUNT_ID with your AWS account ID)
aws iam attach-user-policy \
  --user-name terraform-docmp-user \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/TerraformDOCMPPolicy

# 4. Create access keys
aws iam create-access-key --user-name terraform-docmp-user
# ⚠️ SAVE THE OUTPUT!

# 5. Create S3 bucket for Terraform state
aws s3 mb s3://docmp-terraform-state-YOUR-UNIQUE-ID --region us-east-1
aws s3api put-bucket-versioning \
  --bucket docmp-terraform-state-YOUR-UNIQUE-ID \
  --versioning-configuration Status=Enabled

# 6. Create ECR repositories
aws ecr create-repository --repository-name docmp-app --region us-east-1
aws ecr create-repository --repository-name docmp-app-db-init --region us-east-1
```

---

### Step 2: GitHub Setup (2 minutes)

1. Create GitHub repository
2. Add these secrets (Settings → Secrets → Actions):
   - `AWS_ACCESS_KEY_ID` - from Step 1.3
   - `AWS_SECRET_ACCESS_KEY` - from Step 1.3
   - `AWS_REGION` - e.g., `us-east-1`
   - `TF_STATE_BUCKET` - e.g., `docmp-terraform-state-YOUR-UNIQUE-ID`
   - `ECR_REPOSITORY_NAME` - `docmp-app`
   - `TF_VAR_rds_master_password` - Your secure database password

### Step 3: Configure terraform.tfvars (3 minutes)

```bash
# Copy example
cp terraform.tfvars.example terraform.tfvars

# Edit and update these REQUIRED values:
# - rds_master_password (MUST CHANGE!)
# - s3_bucket_name (MUST BE UNIQUE!)
# - ecs_container_image (UPDATE WITH YOUR ECR URL)
# - availability_zones (MATCH YOUR REGION)
nano terraform.tfvars
```

### Step 4: Deploy (1 command)

**Option A: Via GitHub Actions (Recommended)**
```bash
git add .
git commit -m "Initial infrastructure setup"
git push origin main
```

**Option B: Local Deployment**
```bash
terraform init \
  -backend-config="bucket=docmp-terraform-state-YOUR-UNIQUE-ID" \
  -backend-config="key=docmp/terraform.tfstate" \
  -backend-config="region=us-east-1"

terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### Step 5: Upload Database Files

```bash
# After infrastructure is created, upload your files
aws s3 cp scripts/schema.sql s3://YOUR-BUCKET-NAME/init/schema.sql
aws s3 cp countries.csv s3://YOUR-BUCKET-NAME/static-data/countries.csv
```

## ✅ Verification

```bash
# Check infrastructure
terraform output

# Check ECS cluster
aws ecs list-clusters

# Check RDS instances
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,Endpoint.Address]'

# Get ALB URL
terraform output application_url
```

## 📋 What Gets Created

- ✅ VPC with public/private subnets across 3 AZs
- ✅ Application Load Balancer
- ✅ 2 PostgreSQL RDS instances (Active-Active infrastructure)
- ✅ MSK Kafka cluster (3 brokers)
- ✅ Redis cluster (2 nodes)
- ✅ ECS Fargate cluster with auto-scaling
- ✅ S3 bucket for scripts and data
- ✅ IAM roles and policies
- ✅ CloudWatch logging
- ✅ One-time database initialization

## 🔐 Important Security Notes

1. **NEVER commit terraform.tfvars to Git** - It's already in .gitignore
2. **Use strong passwords** - Minimum 16 characters
3. **Store credentials securely** - Use GitHub Secrets or password manager
4. **Enable MFA** - On AWS root account
5. **Review IAM policies** - Follow least privilege principle

## 💰 Cost Estimate

Approximately **$1,145/month** for production setup:
- RDS: ~$200
- MSK: ~$600
- Redis: ~$100
- ECS: ~$60
- ALB: ~$25
- NAT Gateway: ~$100
- Other: ~$60

**To reduce costs:**
- Use smaller instance types
- Reduce to 2 availability zones
- Use 1 NAT Gateway
- Reduce MSK brokers to 2

## 🛠️ Common Commands

```bash
# View outputs
terraform output

# View state
terraform show

# Refresh state
terraform refresh

# Destroy everything (⚠️ CAREFUL!)
terraform destroy -var-file="terraform.tfvars"

# View logs
aws logs tail /ecs/docmp --follow

# Connect to database
psql -h $(terraform output -raw rds_primary_endpoint | cut -d: -f1) -U docmp_admin -d docmp
```

## 🐛 Troubleshooting

### Issue: terraform.tfvars not found
- Make sure you copied from terraform.tfvars.example
- Check file is in root directory

### Issue: S3 bucket name already exists
- S3 bucket names must be globally unique
- Change `s3_bucket_name` in terraform.tfvars

### Issue: GitHub Actions failing
- Check all secrets are set correctly
- Verify AWS credentials have proper permissions
- Check CloudWatch Logs for details

### Issue: Database initialization failed
```bash
# Check logs
aws logs tail /ecs/docmp/db-init --follow

# Manually trigger
aws ecs run-task \
  --cluster docmp-cluster \
  --task-definition docmp-db-init \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}"
```

## 📚 Next Steps

1. ✅ Infrastructure deployed
2. Configure PostgreSQL replication (see DEPLOYMENT.md Step 8.1)
3. Deploy your application containers
4. Set up monitoring and alerting
5. Configure DNS and SSL certificates
6. Set up backup verification
7. Create disaster recovery plan

## 📖 Full Documentation

- **PREREQUISITES.md** - Detailed prerequisites and IAM policy
- **DEPLOYMENT.md** - Complete deployment guide
- **README.md** - Architecture and usage documentation

## 🆘 Need Help?

1. Check CloudWatch Logs
2. Review Terraform state: `terraform show`
3. Consult AWS documentation
4. Review error messages carefully
5. Check GitHub Actions logs

## 🎯 Success Criteria

Your deployment is successful when:
- [ ] All Terraform resources created without errors
- [ ] ECS tasks running (check AWS Console)
- [ ] ALB health checks passing
- [ ] Database accessible from ECS tasks
- [ ] Database initialization completed
- [ ] Application URL accessible

---

**Ready for detailed setup?** → See PREREQUISITES.md  
**Ready to deploy?** → See DEPLOYMENT.md  
**Need architecture details?** → See README.md