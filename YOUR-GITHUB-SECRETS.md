# Your GitHub Secrets - Quick Setup

Based on your configuration, here are the exact values you need to add as GitHub secrets.

## 🔐 Required Secrets

Go to: `https://github.com/nzeremc/accumulator/settings/secrets/actions`

Click **"New repository secret"** for each of these:

---

### 1. AWS_ACCESS_KEY_ID
**Value**: Your AWS IAM access key ID
```
Example: AKIAIOSFODNN7EXAMPLE
```
**How to get**: AWS Console → IAM → Users → Security credentials → Create access key

---

### 2. AWS_SECRET_ACCESS_KEY
**Value**: Your AWS IAM secret access key
```
Example: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```
**How to get**: Shown only once when creating access key (save it!)

---

### 3. AWS_REGION
**Value**: 
```
ap-south-1
```
**Note**: This is your Mumbai region

---

### 4. TF_STATE_BUCKET
**Value**: 
```
docmp-terraform-state-2101
```
**Note**: This is your S3 bucket for Terraform state

---

### 5. TF_VAR_rds_master_password
**Value**: Your PostgreSQL master password
```
Example: MySecurePassword123!
```
**Requirements**:
- Minimum 8 characters
- Must contain: uppercase, lowercase, numbers
- Can contain: `!@#$%^&*()_+-=[]{}|`

---

### 6. ECR_REPOSITORY_NAME
**Value**: 
```
docmp-app
```
**Note**: This will create `docmp-app` and `docmp-app-db-init` repositories

---

## 📋 Quick Add Using GitHub CLI

If you have GitHub CLI installed:

```bash
cd /Users/hetvi/aws-tf

# Add AWS credentials (you'll be prompted for values)
gh secret set AWS_ACCESS_KEY_ID
gh secret set AWS_SECRET_ACCESS_KEY

# Add region
echo "ap-south-1" | gh secret set AWS_REGION

# Add S3 bucket
echo "docmp-terraform-state-2101" | gh secret set TF_STATE_BUCKET

# Add RDS password (you'll be prompted)
gh secret set TF_VAR_rds_master_password

# Add ECR repository name
echo "docmp-app" | gh secret set ECR_REPOSITORY_NAME
```

---

## ✅ Verify Secrets

After adding all secrets, verify:

```bash
gh secret list
```

You should see all 6 secrets listed.

---

## 🚀 Test the Pipeline

Once secrets are added:

```bash
# Trigger the pipeline
git commit --allow-empty -m "Test pipeline with secrets"
git push origin main

# Watch the pipeline
gh run watch
```

---

## ⚠️ Important Notes

1. **Never commit secrets to Git** - They should only be in GitHub Secrets
2. **AWS credentials** - Make sure the IAM user has the permissions from `terraform-iam-policy.json`
3. **S3 bucket** - Must exist before running the pipeline (you already created it)
4. **RDS password** - Choose a strong password and save it securely

---

## 🔍 Troubleshooting

If the pipeline fails:

1. Check GitHub Actions logs: `https://github.com/nzeremc/accumulator/actions`
2. Verify all 6 secrets are added correctly
3. Ensure AWS credentials have proper IAM permissions
4. Confirm S3 bucket `docmp-terraform-state-2101` exists in `ap-south-1`

---

For detailed instructions, see: **GITHUB-SECRETS-SETUP.md**