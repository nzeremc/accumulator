# DOCMP AWS Infrastructure - Quick Start Guide

## Prerequisites

- AWS Account with appropriate permissions
- Terraform installed (version 1.0 or higher)
- AWS CLI configured
- GitHub repository access
- Docker installed

---

## Step 1: Configure Backend Storage

Edit `provider.tf` and update the S3 backend configuration:

```hcl
backend "s3" {
  bucket  = "your-terraform-state-bucket-name"  # Change this
  key     = "docmp/terraform.tfstate"
  region  = "your-aws-region"                   # Change this
  encrypt = true
}
```

**Example:**
```hcl
backend "s3" {
  bucket  = "docmp-terraform-state-2101"
  key     = "docmp/terraform.tfstate"
  region  = "ap-south-1"
  encrypt = true
}
```

---

## Step 2: Configure Variables

Edit `terraform.tfvars` with your values:

```hcl
# General Configuration
aws_region   = "ap-south-1"
project_name = "docmp"
environment  = "production"

# Terraform Backend
terraform_state_bucket = "docmp-terraform-state-2101"

# Networking
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# RDS Configuration
rds_instance_class    = "db.t3.micro"
rds_allocated_storage = 20
rds_master_username   = "docmp_admin"
rds_engine_version    = "18.3"
```

**Note:** RDS password is auto-generated and stored in AWS Secrets Manager.

---

## Step 3: Prepare Database Files

### SQL Schema Script

Place your schema creation script in `data-files/init/schema.sql`:

```sql
-- Example schema.sql
CREATE SCHEMA IF NOT EXISTS app;

CREATE TABLE app.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Static Data Files

Place CSV or JSON files in `data-files/static-data/`:

```csv
# sample-users.csv
id,username,email,role
1,admin,admin@example.com,admin
2,user1,user1@example.com,user
```

---

## Step 4: Deploy Infrastructure

### Local Deployment

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan -var-file="terraform.tfvars"

# Apply infrastructure
terraform apply -var-file="terraform.tfvars"
```

### GitHub Actions Deployment

1. **Add GitHub Secrets** (Settings → Secrets and variables → Actions):
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

2. **Push to GitHub:**
   ```bash
   git add .
   git commit -m "Deploy infrastructure"
   git push origin main
   ```

3. **Monitor Deployment:**
   - Go to Actions tab in GitHub
   - Watch the workflow progress

---

## Step 5: Verify Deployment

Run the validation script:

```bash
chmod +x validate-infrastructure.sh
./validate-infrastructure.sh
```

Expected output:
- ✅ VPC and subnets created
- ✅ ALB active
- ✅ RDS instances available
- ✅ MSK cluster active
- ✅ Redis available
- ✅ ECS cluster running
- ✅ S3 bucket created

---

## Step 6: Access Database

The RDS database is in a private subnet. To connect:

### Option 1: Check DB Init Logs

```bash
aws logs tail /ecs/docmp-db-init --since 24h --region ap-south-1
```

### Option 2: Use Bastion Host

Create a temporary EC2 instance in the public subnet and connect through it.

### Option 3: Get RDS Password

```bash
# List secrets
aws secretsmanager list-secrets --region ap-south-1

# Get password
aws secretsmanager get-secret-value \
  --secret-id docmp-rds-master-password-XXXXX \
  --region ap-south-1 \
  --query SecretString \
  --output text
```

---

## Step 7: Deploy Application

Build and push your application Docker image:

```bash
# Login to ECR
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  <account-id>.dkr.ecr.ap-south-1.amazonaws.com

# Build image
docker build -t docmp-app .

# Tag image
docker tag docmp-app:latest \
  <account-id>.dkr.ecr.ap-south-1.amazonaws.com/docmp-app:latest

# Push image
docker push <account-id>.dkr.ecr.ap-south-1.amazonaws.com/docmp-app:latest
```

---

## Configuration Reference

### Key Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `aws_region` | AWS region | `ap-south-1` |
| `project_name` | Project name | `docmp` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `rds_instance_class` | RDS instance type | `db.t3.micro` |
| `rds_allocated_storage` | Storage in GB | `20` |
| `msk_instance_type` | MSK broker type | `kafka.t3.small` |
| `redis_node_type` | Redis node type | `cache.t3.micro` |

See `terraform.tfvars.example` for all available options.

---

## Troubleshooting

### Terraform Init Fails

**Issue:** Backend configuration error

**Solution:** Verify S3 bucket exists and region matches in both `provider.tf` and `terraform.tfvars`

### Database Connection Timeout

**Issue:** Cannot connect to RDS from local machine

**Solution:** RDS is in private subnet. Use bastion host or check logs via CloudWatch

### ECS Task Not Starting

**Issue:** Task fails to start

**Solution:** Check logs:
```bash
aws logs tail /ecs/docmp --follow --region ap-south-1
```

---

## Important Notes

1. **One-Time Initialization:** Database initialization runs only once automatically
2. **Security:** All databases are in private subnets with no public access
3. **Passwords:** Auto-generated and stored in AWS Secrets Manager
4. **Backups:** RDS automated backups enabled (configurable retention)
5. **Scaling:** Adjust instance sizes in `terraform.tfvars` as needed

---

## Next Steps

1. ✅ Infrastructure deployed
2. ✅ Database initialized
3. ⏭️ Deploy your application to ECS
4. ⏭️ Configure PostgreSQL replication (if needed)
5. ⏭️ Create Kafka topics in MSK
6. ⏭️ Set up monitoring and alerts

---

## Support

For issues or questions, refer to:
- `README.md` - Detailed documentation
- `GITHUB-SECRETS-SIMPLIFIED.md` - GitHub Actions setup
- `terraform.tfvars.example` - Configuration examples

---

**Infrastructure is ready! Deploy your application and start building! 🚀**