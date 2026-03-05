# DOCMP Infrastructure Deployment Guide

This guide provides step-by-step instructions for deploying the DOCMP infrastructure.

## Prerequisites Checklist

- [ ] AWS Account with administrative access
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.0 installed
- [ ] GitHub account and repository created
- [ ] Docker installed (for building DB init image)
- [ ] S3 bucket created for Terraform state
- [ ] ECR repository created for container images

## Step 1: Prepare AWS Account

### 1.1 Create S3 Bucket for Terraform State

```bash
aws s3 mb s3://docmp-terraform-state --region us-east-1
aws s3api put-bucket-versioning \
  --bucket docmp-terraform-state \
  --versioning-configuration Status=Enabled
```

### 1.2 Create ECR Repositories

```bash
# For application container
aws ecr create-repository --repository-name docmp-app --region us-east-1

# For DB initialization container
aws ecr create-repository --repository-name docmp-app-db-init --region us-east-1
```

### 1.3 Create IAM User for GitHub Actions

```bash
aws iam create-user --user-name github-actions-docmp

# Attach necessary policies
aws iam attach-user-policy \
  --user-name github-actions-docmp \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create access keys
aws iam create-access-key --user-name github-actions-docmp
```

Save the Access Key ID and Secret Access Key for GitHub secrets.

## Step 2: Configure GitHub Repository

### 2.1 Clone and Push Code

```bash
git clone <your-repo-url>
cd aws-tf
git remote add origin <your-repo-url>
git add .
git commit -m "Initial commit: DOCMP infrastructure"
git push -u origin main
```

### 2.2 Configure GitHub Secrets

Go to your repository → Settings → Secrets and variables → Actions

Add the following secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ACCESS_KEY_ID` | `AKIA...` | AWS access key from Step 1.3 |
| `AWS_SECRET_ACCESS_KEY` | `xxxxx` | AWS secret key from Step 1.3 |
| `AWS_REGION` | `us-east-1` | Your AWS region |
| `TF_STATE_BUCKET` | `docmp-terraform-state` | S3 bucket for state |
| `ECR_REPOSITORY_NAME` | `docmp-app` | ECR repository name |

## Step 3: Prepare Configuration Files

### 3.1 Create terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3.2 Edit terraform.tfvars

Update with your specific values:

```hcl
# General Configuration
aws_region   = "us-east-1"
project_name = "docmp"
environment  = "production"

# Networking Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# RDS PostgreSQL Configuration
rds_instance_class          = "db.t3.large"
rds_allocated_storage       = 100
rds_engine_version          = "15.4"
rds_database_name           = "docmp"
rds_master_username         = "docmp_admin"
rds_master_password         = "CHANGE_TO_SECURE_PASSWORD_HERE"
rds_backup_retention_period = 7
rds_multi_az                = true

# MSK Configuration
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
ecs_container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/docmp-app:latest"
ecs_container_port  = 8080

# S3 Configuration
s3_bucket_name        = "docmp-data-unique-name-12345"
s3_versioning_enabled = true

# Database Initialization
db_init_script_s3_key       = "init/schema.sql"
db_init_static_files_prefix = "static-data/"
enable_db_initialization    = true
```

**Important**: 
- Change `rds_master_password` to a strong password
- Update `s3_bucket_name` to a globally unique name
- Update `ecs_container_image` with your ECR repository URL

## Step 4: Prepare Database Files

### 4.1 Prepare SQL Schema

Create your `schema.sql` file or use the example:

```bash
cp scripts/schema.sql.example scripts/schema.sql
# Edit schema.sql with your actual schema
```

### 4.2 Prepare Static Data Files

Create CSV files for static data. Example `countries.csv`:

```csv
code,name,is_active
USA,United States,true
CAN,Canada,true
GBR,United Kingdom,true
```

### 4.3 Upload to S3

After infrastructure is created, upload files:

```bash
# Upload SQL script
aws s3 cp scripts/schema.sql s3://docmp-data-unique-name-12345/init/schema.sql

# Upload static data files
aws s3 cp countries.csv s3://docmp-data-unique-name-12345/static-data/countries.csv
aws s3 cp categories.csv s3://docmp-data-unique-name-12345/static-data/categories.csv
```

## Step 5: Build and Push DB Init Container

### 5.1 Build Docker Image

```bash
cd scripts
docker build -f Dockerfile.db-init -t docmp-db-init:latest .
```

### 5.2 Tag and Push to ECR

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Tag image
docker tag docmp-db-init:latest \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/docmp-app-db-init:latest

# Push image
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/docmp-app-db-init:latest
```

## Step 6: Deploy Infrastructure

### Option A: Local Deployment

```bash
# Initialize Terraform
terraform init \
  -backend-config="bucket=docmp-terraform-state" \
  -backend-config="key=docmp/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true"

# Validate configuration
terraform validate

# Plan deployment
terraform plan -var-file="terraform.tfvars" -out=tfplan

# Review the plan carefully
# If everything looks good, apply
terraform apply tfplan
```

### Option B: GitHub Actions Deployment

```bash
# Commit and push terraform.tfvars (encrypted or use GitHub secrets)
git add terraform.tfvars
git commit -m "Add configuration"
git push origin main
```

GitHub Actions will automatically:
1. Validate Terraform
2. Plan changes
3. Apply infrastructure
4. Build and push DB init image

## Step 7: Verify Deployment

### 7.1 Check Infrastructure

```bash
# Get outputs
terraform output

# Check ECS cluster
aws ecs list-clusters

# Check RDS instances
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,Endpoint.Address]'

# Check ALB
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,DNSName]'
```

### 7.2 Verify Database Initialization

```bash
# Check ECS task logs
aws logs tail /ecs/docmp/db-init --follow

# Or check in AWS Console:
# ECS → Clusters → docmp-cluster → Tasks → Select db-init task → Logs
```

### 7.3 Test Database Connection

```bash
# Get database credentials from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id docmp-db-master-xxxxx \
  --query SecretString \
  --output text | jq .

# Connect to database (from a bastion host or ECS task)
psql -h <primary-endpoint> -U docmp_admin -d docmp
```

## Step 8: Post-Deployment Configuration

### 8.1 Configure PostgreSQL Replication (Manual)

The infrastructure enables logical replication at the parameter level. You need to manually configure:

1. **On Primary Database:**

```sql
-- Create publication
CREATE PUBLICATION docmp_pub FOR ALL TABLES;

-- Verify
SELECT * FROM pg_publication;
```

2. **On Secondary Database:**

```sql
-- Create subscription
CREATE SUBSCRIPTION docmp_sub
CONNECTION 'host=<primary-endpoint> port=5432 dbname=docmp user=docmp_admin password=<password>'
PUBLICATION docmp_pub;

-- Verify
SELECT * FROM pg_subscription;
SELECT * FROM pg_stat_subscription;
```

### 8.2 Configure Application

Update your application configuration with:

- ALB DNS name (from outputs)
- Database endpoints (from outputs)
- Redis endpoint (from outputs)
- Kafka brokers (from outputs)

### 8.3 Set Up DNS (Optional)

```bash
# Create Route53 hosted zone
aws route53 create-hosted-zone --name docmp.example.com --caller-reference $(date +%s)

# Create A record pointing to ALB
# Use AWS Console or CLI to create alias record
```

### 8.4 Configure SSL Certificate (Optional)

```bash
# Request certificate
aws acm request-certificate \
  --domain-name docmp.example.com \
  --validation-method DNS \
  --region us-east-1

# After validation, update terraform.tfvars
# certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxx"

# Re-apply Terraform
terraform apply -var-file="terraform.tfvars"
```

## Step 9: Monitoring Setup

### 9.1 CloudWatch Dashboards

Create custom dashboards for:
- ECS metrics (CPU, Memory, Task count)
- RDS metrics (Connections, CPU, Storage)
- ALB metrics (Request count, Target health)
- MSK metrics (Broker metrics)
- Redis metrics (Cache hits, Evictions)

### 9.2 CloudWatch Alarms

Set up alarms for:
- High CPU usage
- Low disk space
- Failed health checks
- High error rates

## Troubleshooting

### Issue: Terraform State Lock

```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Issue: Database Initialization Failed

```bash
# Check logs
aws logs tail /ecs/docmp/db-init --follow

# Manually run initialization task
aws ecs run-task \
  --cluster docmp-cluster \
  --task-definition docmp-db-init \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}"
```

### Issue: ECS Tasks Not Starting

```bash
# Check service events
aws ecs describe-services --cluster docmp-cluster --services docmp-service

# Check task definition
aws ecs describe-task-definition --task-definition docmp-app

# Check IAM roles
aws iam get-role --role-name docmp-ecs-task-execution-role
```

## Rollback Procedure

If deployment fails:

```bash
# Destroy infrastructure
terraform destroy -var-file="terraform.tfvars"

# Or rollback to previous state
terraform state pull > backup.tfstate
terraform state push previous.tfstate
```

## Maintenance

### Regular Updates

```bash
# Update Terraform modules
terraform get -update

# Update provider versions
terraform init -upgrade

# Apply updates
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### Backup Verification

```bash
# List RDS snapshots
aws rds describe-db-snapshots --db-instance-identifier docmp-postgres-primary

# Test restore (in separate environment)
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier docmp-test \
  --db-snapshot-identifier snapshot-id
```

## Security Checklist

- [ ] Changed default passwords
- [ ] Enabled MFA for AWS root account
- [ ] Configured VPC flow logs
- [ ] Enabled CloudTrail
- [ ] Configured AWS Config
- [ ] Set up AWS GuardDuty
- [ ] Reviewed security group rules
- [ ] Enabled encryption at rest for all services
- [ ] Configured backup retention policies
- [ ] Set up monitoring and alerting

## Next Steps

1. Deploy your application containers
2. Configure application-level monitoring
3. Set up log aggregation
4. Configure backup and disaster recovery procedures
5. Implement CI/CD for application deployments
6. Set up staging environment (duplicate infrastructure)
7. Configure PostgreSQL replication monitoring
8. Implement automated testing

## Support

For issues or questions:
- Check CloudWatch Logs
- Review Terraform state
- Consult AWS documentation
- Create GitHub issue

---

**Deployment Date**: _____________  
**Deployed By**: _____________  
**Environment**: _____________  
**Version**: _____________