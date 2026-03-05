# GitHub Secrets Setup Guide

This guide explains how to add the required secrets to your GitHub repository for the CI/CD pipeline to work.

## Required GitHub Secrets

The GitHub Actions workflow requires the following secrets:

| Secret Name | Description | Example Value |
|------------|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | AWS IAM user access key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM user secret access key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | AWS region for deployment | `ap-south-1` |
| `TF_STATE_BUCKET` | S3 bucket name for Terraform state | `docmp-terraform-state-2101` |
| `TF_VAR_rds_master_password` | PostgreSQL master password | `YourSecurePassword123!` |
| `ECR_REPOSITORY_NAME` | ECR repository base name | `docmp-app` |

---

## Step-by-Step Instructions

### Method 1: Using GitHub Web Interface (Recommended)

1. **Navigate to Your Repository**
   - Go to: `https://github.com/nzeremc/accumulator`

2. **Access Settings**
   - Click on **Settings** tab (top right of repository page)

3. **Navigate to Secrets**
   - In the left sidebar, click **Secrets and variables**
   - Click **Actions**

4. **Add Each Secret**
   - Click **New repository secret** button
   - Enter the **Name** (exactly as shown in the table above)
   - Enter the **Value**
   - Click **Add secret**

5. **Repeat for All Secrets**
   - Add all 6 secrets listed in the table above

---

### Method 2: Using GitHub CLI

If you have GitHub CLI installed, you can add secrets from the command line:

```bash
# Install GitHub CLI if not already installed
# macOS: brew install gh
# Login to GitHub
gh auth login

# Navigate to your repository directory
cd /Users/hetvi/aws-tf

# Add each secret
gh secret set AWS_ACCESS_KEY_ID
# Paste your AWS access key ID when prompted

gh secret set AWS_SECRET_ACCESS_KEY
# Paste your AWS secret access key when prompted

gh secret set AWS_REGION
# Enter: ap-south-1

gh secret set TF_STATE_BUCKET
# Enter: docmp-terraform-state-2101

gh secret set TF_VAR_rds_master_password
# Enter your PostgreSQL password

gh secret set ECR_REPOSITORY_NAME
# Enter: docmp-app
```

---

## How to Get the Values

### 1. AWS Credentials (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`)

**Option A: Create New IAM User (Recommended)**

1. Go to AWS Console → IAM → Users
2. Click **Add users**
3. Username: `github-actions-terraform`
4. Select **Access key - Programmatic access**
5. Click **Next: Permissions**
6. Attach the IAM policy from `terraform-iam-policy.json`
7. Click through to **Create user**
8. **IMPORTANT**: Copy the Access Key ID and Secret Access Key
   - You won't be able to see the secret key again!

**Option B: Use Existing IAM User**

If you already have an IAM user with appropriate permissions:
1. Go to AWS Console → IAM → Users
2. Select your user
3. Go to **Security credentials** tab
4. Click **Create access key**
5. Select **Application running outside AWS**
6. Copy the Access Key ID and Secret Access Key

### 2. AWS Region (`AWS_REGION`)

Use the region where you want to deploy:
- Your current region: `ap-south-1` (Mumbai)
- Other examples: `us-east-1`, `eu-west-1`, `ap-southeast-1`

### 3. Terraform State Bucket (`TF_STATE_BUCKET`)

Use the S3 bucket you created for Terraform state:
- Your bucket: `docmp-terraform-state-2101`

### 4. RDS Master Password (`TF_VAR_rds_master_password`)

Create a strong password for PostgreSQL:
- Minimum 8 characters
- Must contain uppercase, lowercase, numbers
- Can contain special characters: `!@#$%^&*()_+-=[]{}|`
- Example: `MySecurePass123!`

### 5. ECR Repository Name (`ECR_REPOSITORY_NAME`)

Use your project name:
- Value: `docmp-app`
- This will create repositories: `docmp-app` and `docmp-app-db-init`

---

## Verification

After adding all secrets, verify they are set correctly:

### Using GitHub Web Interface

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. You should see all 6 secrets listed
3. Secrets will show as `••••••••` (hidden)

### Using GitHub CLI

```bash
gh secret list
```

Expected output:
```
AWS_ACCESS_KEY_ID        Updated 2024-XX-XX
AWS_SECRET_ACCESS_KEY    Updated 2024-XX-XX
AWS_REGION               Updated 2024-XX-XX
TF_STATE_BUCKET          Updated 2024-XX-XX
TF_VAR_rds_master_password Updated 2024-XX-XX
ECR_REPOSITORY_NAME      Updated 2024-XX-XX
```

---

## Testing the Pipeline

Once all secrets are added:

1. **Trigger the Pipeline**
   ```bash
   # Make a small change and push
   git commit --allow-empty -m "Test GitHub Actions pipeline"
   git push origin main
   ```

2. **Monitor the Pipeline**
   - Go to your repository on GitHub
   - Click **Actions** tab
   - You should see the workflow running
   - Click on the workflow run to see details

3. **Check for Errors**
   - If the workflow fails, check the logs
   - Common issues:
     - Invalid AWS credentials
     - Insufficient IAM permissions
     - S3 bucket doesn't exist
     - Invalid region

---

## Security Best Practices

1. **Never commit secrets to Git**
   - Secrets should only be in GitHub Secrets
   - Never in code or terraform.tfvars

2. **Use least privilege IAM permissions**
   - Only grant permissions needed for Terraform
   - Use the IAM policy from `terraform-iam-policy.json`

3. **Rotate credentials regularly**
   - Change AWS access keys every 90 days
   - Update GitHub secrets when rotating

4. **Use different credentials for different environments**
   - If you add dev/staging/prod later, use separate IAM users

5. **Enable MFA for IAM users**
   - Add multi-factor authentication to IAM users
   - Especially for users with admin access

---

## Troubleshooting

### Pipeline fails with "Access Denied"

**Problem**: AWS credentials don't have sufficient permissions

**Solution**:
1. Check IAM user has the policy from `terraform-iam-policy.json`
2. Verify credentials are correct in GitHub Secrets
3. Check AWS region matches your resources

### Pipeline fails with "Bucket does not exist"

**Problem**: S3 state bucket not found

**Solution**:
1. Verify bucket name in `TF_STATE_BUCKET` secret
2. Check bucket exists in AWS Console
3. Verify bucket is in the correct region

### Pipeline fails with "Invalid credentials"

**Problem**: AWS access key or secret key is incorrect

**Solution**:
1. Regenerate AWS access keys in IAM Console
2. Update GitHub secrets with new values
3. Ensure no extra spaces in secret values

### Pipeline runs but doesn't apply changes

**Problem**: Pipeline only runs on push to main branch

**Solution**:
- Ensure you're pushing to `main` branch
- Pull requests will only run `terraform plan`
- Only pushes to `main` will run `terraform apply`

---

## Next Steps

After adding all secrets:

1. ✅ Verify all 6 secrets are added
2. ✅ Test the pipeline with an empty commit
3. ✅ Monitor the first workflow run
4. ✅ Check Terraform outputs after successful run
5. ✅ Verify AWS resources are created

---

## Quick Reference Commands

```bash
# List all secrets
gh secret list

# Update a secret
gh secret set SECRET_NAME

# Delete a secret
gh secret delete SECRET_NAME

# View workflow runs
gh run list

# View specific workflow run
gh run view <run-id>

# Watch workflow run in real-time
gh run watch
```

---

## Support

If you encounter issues:

1. Check the GitHub Actions logs for detailed error messages
2. Review the Terraform plan output
3. Verify all secrets are set correctly
4. Ensure AWS credentials have proper permissions
5. Check the DEPLOYMENT.md guide for additional help

---

**Important**: Keep your secrets secure and never share them publicly!