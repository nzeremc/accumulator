# AWS Console Setup Guide - Step by Step

This guide provides detailed steps with visual references for setting up AWS resources via the Console.

---

## 📋 Prerequisites

- AWS Account (sign up at https://aws.amazon.com)
- Access to AWS Console
- This repository cloned locally

---

## Step 1: Create IAM User

### 1.1 Navigate to IAM

1. Log in to AWS Console: https://console.aws.amazon.com
2. In the search bar at top, type **IAM**
3. Click on **IAM** service

### 1.2 Create User

1. In left sidebar, click **Users**
2. Click **Create user** button (orange button, top right)
3. Enter user details:
   - **User name**: `terraform-docmp-user`
4. Click **Next** button

### 1.3 Set Permissions

1. Select **Attach policies directly**
2. Click **Create policy** button (this opens a new tab)

---

## Step 2: Create IAM Policy

### 2.1 Open Policy Editor

In the new tab that opened:
1. You should see "Create policy" page
2. Click on **JSON** tab (next to Visual)

### 2.2 Add Policy JSON

1. **Delete** all existing content in the editor
2. Open the file `terraform-iam-policy.json` from this repository
3. **Copy** the entire content
4. **Paste** it into the AWS policy editor
5. Click **Next** button

### 2.3 Name the Policy

1. **Policy name**: `TerraformDOCMPPolicy`
2. **Description**: `Policy for Terraform to manage DOCMP infrastructure`
3. Scroll down and click **Create policy** button

✅ You should see a success message: "Policy TerraformDOCMPPolicy created"

---

## Step 3: Attach Policy to User

### 3.1 Return to User Creation

1. Go back to the previous tab (user creation)
2. Click the **refresh icon** (circular arrow) next to the search box
3. In the search box, type: `TerraformDOCMPPolicy`
4. **Check the box** next to `TerraformDOCMPPolicy`
5. Click **Next** button
6. Review the settings
7. Click **Create user** button

✅ You should see: "User terraform-docmp-user created successfully"

---

## Step 4: Create Access Keys

### 4.1 Navigate to User

1. Click on the user name: `terraform-docmp-user`
2. Click on **Security credentials** tab

### 4.2 Create Access Key

1. Scroll down to **Access keys** section
2. Click **Create access key** button
3. Select use case: **Command Line Interface (CLI)**
4. Check the confirmation box: "I understand the above recommendation..."
5. Click **Next** button

### 4.3 Add Description (Optional)

1. Description tag: `Terraform DOCMP deployment`
2. Click **Create access key** button

### 4.4 Save Credentials

⚠️ **CRITICAL STEP - DO NOT SKIP!**

1. Click **Download .csv file** button
2. Save the file to a secure location
3. **Copy and save** the following (you'll need these for GitHub):
   - **Access key ID**: `AKIAIOSFODNN7EXAMPLE`
   - **Secret access key**: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`

4. Click **Done** button

⚠️ **WARNING**: You cannot retrieve the secret access key again. If you lose it, you must create a new access key.

---

## Step 5: Create S3 Bucket for Terraform State

### 5.1 Navigate to S3

1. In the AWS Console search bar, type **S3**
2. Click on **S3** service

### 5.2 Create Bucket

1. Click **Create bucket** button (orange button)
2. Enter bucket details:
   - **Bucket name**: `docmp-terraform-state-YOUR-UNIQUE-ID`
     - Replace `YOUR-UNIQUE-ID` with something unique (e.g., your company name + random numbers)
     - Example: `docmp-terraform-state-acme-12345`
   - **AWS Region**: `US East (N. Virginia) us-east-1` (or your preferred region)

### 5.3 Configure Bucket Settings

1. **Object Ownership**: Keep default (ACLs disabled)
2. **Block Public Access settings**: Keep all checked ✅ (default)
3. **Bucket Versioning**: Select **Enable**
4. **Default encryption**: 
   - Encryption type: **Server-side encryption with Amazon S3 managed keys (SSE-S3)**
   - Bucket Key: **Enable**
5. Scroll down and click **Create bucket** button

✅ You should see: "Successfully created bucket docmp-terraform-state-YOUR-UNIQUE-ID"

**Save this bucket name** - you'll need it for:
- GitHub Secret: `TF_STATE_BUCKET`
- terraform.tfvars configuration

---

## Step 6: Create ECR Repositories

### 6.1 Navigate to ECR

1. In the AWS Console search bar, type **ECR**
2. Click on **Elastic Container Registry**

### 6.2 Create First Repository

1. Click **Create repository** button
2. **Visibility settings**: Private (default)
3. **Repository name**: `docmp-app`
4. **Tag immutability**: Disabled (default)
5. **Scan on push**: **Enable** ✅
6. **KMS encryption**: Disabled (default)
7. Click **Create repository** button

### 6.3 Save Repository URI

After creation, you'll see the repository details:
- **Copy the URI**: `123456789012.dkr.ecr.us-east-1.amazonaws.com/docmp-app`
- Save this - you'll need it for `terraform.tfvars`

### 6.4 Create Second Repository

1. Click **Create repository** button again
2. **Repository name**: `docmp-app-db-init`
3. **Scan on push**: **Enable** ✅
4. Click **Create repository** button
5. **Copy the URI**: `123456789012.dkr.ecr.us-east-1.amazonaws.com/docmp-app-db-init`

✅ You should now have 2 repositories:
- `docmp-app`
- `docmp-app-db-init`

---

## Step 7: Verify Your Setup

### Checklist

- [ ] IAM user `terraform-docmp-user` created
- [ ] IAM policy `TerraformDOCMPPolicy` created and attached
- [ ] Access keys created and saved securely
- [ ] S3 bucket created with versioning enabled
- [ ] Two ECR repositories created
- [ ] All URIs and credentials saved

### What You Should Have

| Item | Value | Where to Use |
|------|-------|--------------|
| AWS Access Key ID | `AKIAIOSFODNN7EXAMPLE` | GitHub Secret |
| AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG...` | GitHub Secret |
| S3 State Bucket | `docmp-terraform-state-YOUR-UNIQUE-ID` | GitHub Secret |
| ECR App URI | `123456789012.dkr.ecr.us-east-1.amazonaws.com/docmp-app` | terraform.tfvars |
| ECR DB Init URI | `123456789012.dkr.ecr.us-east-1.amazonaws.com/docmp-app-db-init` | terraform.tfvars |
| AWS Region | `us-east-1` | GitHub Secret & terraform.tfvars |

---

## Step 8: Configure GitHub Secrets

### 8.1 Navigate to Repository Settings

1. Go to your GitHub repository
2. Click **Settings** tab
3. In left sidebar, expand **Secrets and variables**
4. Click **Actions**

### 8.2 Add Secrets

Click **New repository secret** for each of these:

#### Secret 1: AWS_ACCESS_KEY_ID
- **Name**: `AWS_ACCESS_KEY_ID`
- **Secret**: Paste your Access Key ID from Step 4.4
- Click **Add secret**

#### Secret 2: AWS_SECRET_ACCESS_KEY
- **Name**: `AWS_SECRET_ACCESS_KEY`
- **Secret**: Paste your Secret Access Key from Step 4.4
- Click **Add secret**

#### Secret 3: AWS_REGION
- **Name**: `AWS_REGION`
- **Secret**: `us-east-1` (or your chosen region)
- Click **Add secret**

#### Secret 4: TF_STATE_BUCKET
- **Name**: `TF_STATE_BUCKET`
- **Secret**: Your S3 bucket name from Step 5
- Click **Add secret**

#### Secret 5: ECR_REPOSITORY_NAME
- **Name**: `ECR_REPOSITORY_NAME`
- **Secret**: `docmp-app`
- Click **Add secret**

#### Secret 6: TF_VAR_rds_master_password (Optional)
- **Name**: `TF_VAR_rds_master_password`
- **Secret**: Your secure database password (16+ characters)
- Click **Add secret**

✅ You should now have 6 secrets configured

---

## Step 9: Configure terraform.tfvars

### 9.1 Copy Example File

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 9.2 Edit Required Values

Open `terraform.tfvars` and update:

```hcl
# REQUIRED: Update these values
aws_region   = "us-east-1"  # Match your region
project_name = "docmp"
environment  = "production"

# REQUIRED: Update availability zones for your region
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# REQUIRED: Strong password (or use GitHub Secret)
rds_master_password = "CHANGE_TO_STRONG_PASSWORD_HERE"

# REQUIRED: Globally unique bucket name
s3_bucket_name = "docmp-data-YOUR-UNIQUE-ID"

# REQUIRED: Your ECR repository URI from Step 6
ecs_container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/docmp-app:latest"
```

---

## Step 10: Deploy Infrastructure

### Option A: Via GitHub Actions (Recommended)

```bash
git add .
git commit -m "Initial infrastructure setup"
git push origin main
```

GitHub Actions will automatically:
1. Validate Terraform
2. Plan infrastructure
3. Apply changes
4. Build and push Docker images

### Option B: Local Deployment

```bash
# Initialize Terraform
terraform init \
  -backend-config="bucket=docmp-terraform-state-YOUR-UNIQUE-ID" \
  -backend-config="key=docmp/terraform.tfstate" \
  -backend-config="region=us-east-1"

# Plan
terraform plan -var-file="terraform.tfvars"

# Apply
terraform apply -var-file="terraform.tfvars"
```

---

## 🎉 Success!

If everything is configured correctly:
- ✅ Terraform will create all infrastructure
- ✅ Database will be initialized automatically
- ✅ ECS services will start running
- ✅ Application will be accessible via ALB

---

## 🆘 Troubleshooting

### Issue: "Access Denied" errors
- Verify IAM policy is attached to user
- Check access keys are correct in GitHub Secrets

### Issue: "Bucket already exists"
- S3 bucket names must be globally unique
- Choose a different name in terraform.tfvars

### Issue: "Invalid credentials"
- Verify access keys are copied correctly
- Check for extra spaces or line breaks

### Issue: GitHub Actions failing
- Check all 6 secrets are configured
- Verify secret names match exactly (case-sensitive)
- Check CloudWatch Logs for detailed errors

---

## 📞 Need Help?

- Review QUICKSTART.md for condensed steps
- Check PREREQUISITES.md for detailed requirements
- See DEPLOYMENT.md for deployment guide
- Consult README.md for architecture details

---

## 🔐 Security Reminders

- ✅ Never commit access keys to Git
- ✅ Never share access keys publicly
- ✅ Store credentials in password manager
- ✅ Enable MFA on AWS root account
- ✅ Rotate access keys every 90 days
- ✅ Use strong passwords (16+ characters)
- ✅ Review IAM policies regularly

---

**Next Steps**: After AWS setup is complete, proceed to QUICKSTART.md Step 2 (GitHub Setup)