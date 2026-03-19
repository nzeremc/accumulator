# DOCMP Infrastructure Deployment Guide

## 📋 Overview

This guide covers the deployment of the DOCMP (Document Management Platform) infrastructure with 3 ECS task definitions for application deployment, database initialization, and PostgreSQL replication setup.

## 🏗️ Architecture Components

### ECS Task Definitions

1. **App Task Definition** - Main application service (long-running)
2. **DB Init Task Definition** - Database schema creation and data loading (one-time)
3. **PGActive Task Definition** - PostgreSQL logical replication setup (one-time)

### Infrastructure Resources

- **VPC** with public/private subnets across 3 AZs
- **VPC Endpoints** for private AWS service access (S3, ECR, Secrets Manager, CloudWatch, ECS, STS)
- **RDS PostgreSQL** - Primary and Secondary instances with logical replication
- **ECS Fargate** - Container orchestration
- **ALB** - Application Load Balancer
- **MSK** - Managed Kafka
- **ElastiCache Redis** - Caching layer
- **ECR** - Container image repositories (app, db-init, pgactive)
- **S3** - SQL scripts and static data storage
- **Secrets Manager** - Credentials management

## 🔒 AWS GovCloud Compatibility

✅ **100% GovCloud Ready**

- Uses `aws_partition` data source for dynamic ARN generation
- Works in both commercial AWS and GovCloud
- VPC endpoints configured for fully private access
- All resources deployed in private subnets

## 🚀 Deployment Steps

### Prerequisites

1. AWS Account with appropriate permissions
2. Terraform >= 1.0
3. AWS CLI configured
4. GitHub repository with secrets configured

### Step 1: Configure Variables

Edit `terraform.tfvars`:

```hcl
aws_region   = "ap-south-1"  # or us-gov-west-1 for GovCloud
project_name = "docmp"
environment  = "production"

# Adjust instance sizes based on your needs
rds_instance_class = "db.t3.micro"  # Free tier or larger
ecs_task_cpu       = "1024"
ecs_task_memory    = "2048"
```

### Step 2: Deploy Infrastructure

#### Option A: Via GitHub Actions (Recommended)

1. Go to GitHub Actions tab
2. Select "Terraform Infrastructure Deployment"
3. Click "Run workflow"
4. Choose action: `plan` (to preview) or `apply` (to deploy)
5. Click "Run workflow" button

#### Option B: Via CLI

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan -var-file="terraform.tfvars"

# Apply changes
terraform apply -var-file="terraform.tfvars"
```

### Step 3: Build and Push Docker Images

Images are automatically built by GitHub Actions when you run `apply`. Alternatively, build manually:

```bash
# Get ECR login
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com

# Build and push db-init image
cd scripts
docker build -f Dockerfile.db-init -t <account-id>.dkr.ecr.<region>.amazonaws.com/docmp-app-db-init:latest .
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/docmp-app-db-init:latest

# Build and push pgactive image
docker build -f Dockerfile.pgactive -t <account-id>.dkr.ecr.<region>.amazonaws.com/docmp-pgactive:latest .
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/docmp-pgactive:latest
```

### Step 4: Run DB Initialization Task (One-Time)

```bash
# Get cluster name and subnet/security group IDs from Terraform outputs
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SUBNET_IDS=$(terraform output -json private_subnet_ids | jq -r '.[]' | paste -sd "," -)
SG_ID=$(terraform output -raw ecs_tasks_security_group_id)

# Run db-init task
aws ecs run-task \
  --cluster $CLUSTER_NAME \
  --task-definition docmp-db-init \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_IDS],securityGroups=[$SG_ID],assignPublicIp=DISABLED}" \
  --region <your-region>
```

**What it does:**
- Creates `docmp` schema
- Creates all tables (sponsor, id, monetary_accumulator, etc.)
- Loads static data from S3
- Marks initialization as complete

### Step 5: Run PGActive Replication Setup (One-Time)

**Important:** Run this AFTER db-init completes successfully.

```bash
# Run pgactive task
aws ecs run-task \
  --cluster $CLUSTER_NAME \
  --task-definition docmp-pgactive \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_IDS],securityGroups=[$SG_ID],assignPublicIp=DISABLED}" \
  --region <your-region>
```

**What it does:**
- Creates replication slot on primary database
- Sets up publication for all tables
- Creates subscription on secondary database
- Tests replication with sample data
- Verifies replication lag

### Step 6: Verify Deployment

```bash
# Check ECS service status
aws ecs describe-services \
  --cluster $CLUSTER_NAME \
  --services docmp-service \
  --region <your-region>

# Check task logs
aws logs tail /ecs/docmp --follow --region <your-region>
aws logs tail /ecs/docmp/db-init --follow --region <your-region>
aws logs tail /ecs/docmp/pgactive --follow --region <your-region>

# Get application URL
terraform output application_url
```

## 📊 Monitoring

### CloudWatch Log Groups

- `/ecs/docmp` - Application logs
- `/ecs/docmp/db-init` - DB initialization logs
- `/ecs/docmp/pgactive` - Replication setup logs

### Check Replication Status

```bash
# Connect to primary database
psql -h <primary-endpoint> -U docmp_admin -d docmp

# Check replication slots
SELECT * FROM pg_replication_slots;

# Check replication lag
SELECT now() - pg_last_xact_replay_timestamp() AS replication_lag;
```

## 🔧 Troubleshooting

### DB Init Task Fails

1. Check CloudWatch logs: `/ecs/docmp/db-init`
2. Verify S3 bucket has `init/schema.sql` and `static-data/` files
3. Verify IAM roles have S3 and Secrets Manager permissions
4. Check database connectivity from ECS tasks

### PGActive Task Fails

1. Check CloudWatch logs: `/ecs/docmp/pgactive`
2. Verify db-init completed successfully first
3. Check RDS parameter group has `rds.logical_replication = 1`
4. Verify both primary and secondary databases are accessible
5. Check replication slot doesn't already exist

### App Service Not Starting

1. Check ECS service events
2. Verify container image exists in ECR
3. Check security group rules allow ALB → ECS communication
4. Verify environment variables and secrets are correct

## 🗑️ Cleanup

### Via GitHub Actions

1. Go to GitHub Actions
2. Run workflow with action: `destroy`

### Via CLI

```bash
terraform destroy -var-file="terraform.tfvars"
```

## 📝 Important Notes

1. **Database Credentials**: Auto-generated and stored in AWS Secrets Manager
2. **Replication**: Logical replication is configured at infrastructure level
3. **VPC Endpoints**: Reduce NAT Gateway costs and improve security
4. **Task Execution**: db-init and pgactive are one-time tasks, not services
5. **GovCloud**: Change region to `us-gov-west-1` or `us-gov-east-1`

## 🔐 Security Best Practices

- ✅ All resources in private subnets
- ✅ VPC endpoints for AWS service access
- ✅ Secrets in AWS Secrets Manager
- ✅ Encrypted RDS storage
- ✅ Encrypted S3 buckets
- ✅ Security groups with least privilege
- ✅ IAM roles with minimal permissions
- ✅ Container image scanning enabled

## 📞 Support

For issues or questions:
1. Check CloudWatch logs
2. Review Terraform plan output
3. Verify AWS service quotas
4. Check IAM permissions

## 🎯 Next Steps

After successful deployment:
1. Configure DNS for ALB
2. Set up SSL certificate
3. Configure application environment variables
4. Set up monitoring and alerting
5. Configure backup policies
6. Set up CI/CD for application deployments

---

