# DOCMP AWS Infrastructure Automation

This repository contains Terraform code to provision and manage the complete AWS infrastructure for the DOCMP system, including one-time database initialization.

## 🏗️ Architecture Overview

The infrastructure includes:

- **Networking**: VPC with public and private subnets across multiple availability zones
- **Application Load Balancer**: For distributing traffic to ECS services
- **PostgreSQL (Active-Active)**: Two RDS PostgreSQL instances with logical replication enabled at infrastructure level
- **MSK (Kafka)**: Managed Kafka cluster for messaging
- **Redis**: ElastiCache cluster with high availability
- **ECS**: Fargate-based container orchestration
- **S3**: Storage for SQL scripts and static data files
- **IAM**: Roles and policies for secure access

## 📋 Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0
- AWS CLI configured
- GitHub repository for CI/CD
- Docker (for building DB initialization image)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd aws-tf
```

### 2. Configure Variables

Copy the example tfvars file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
# General Configuration
aws_region   = "us-east-1"
project_name = "docmp"
environment  = "production"

# Networking
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# RDS Configuration
rds_instance_class    = "db.t3.large"
rds_allocated_storage = 100
rds_master_username   = "docmp_admin"
rds_master_password   = "CHANGE_ME_SECURE_PASSWORD"

# ... (see terraform.tfvars.example for all options)
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan Infrastructure

```bash
terraform plan -var-file="terraform.tfvars"
```

### 5. Apply Infrastructure

```bash
terraform apply -var-file="terraform.tfvars"
```

## 🔄 CI/CD with GitHub Actions

### Setup GitHub Secrets

Configure the following secrets in your GitHub repository:

- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `AWS_REGION`: AWS region (e.g., us-east-1)
- `TF_STATE_BUCKET`: S3 bucket for Terraform state
- `ECR_REPOSITORY_NAME`: ECR repository name for container images

### Workflow

The GitHub Actions workflow automatically:

1. Validates Terraform configuration
2. Plans infrastructure changes
3. Applies changes on push to main branch
4. Builds and pushes DB initialization Docker image
5. Triggers one-time database initialization

## 📊 Database Initialization

### How It Works

1. Infrastructure is provisioned via Terraform
2. PostgreSQL instances are created with the DOCMP database
3. A one-time ECS task runs automatically
4. The task:
   - Fetches SQL script from S3
   - Executes schema creation
   - Loads static data files from S3
   - Marks initialization as complete

### Preparing Database Files

#### 1. SQL Schema Script

Create your schema script and upload to S3:

```bash
aws s3 cp schema.sql s3://your-bucket-name/init/schema.sql
```

Example `schema.sql`:

```sql
-- Create schemas
CREATE SCHEMA IF NOT EXISTS app;
CREATE SCHEMA IF NOT EXISTS audit;

-- Create tables
CREATE TABLE app.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Add more tables as needed
```

#### 2. Static Data Files

Upload CSV files to S3:

```bash
aws s3 cp countries.csv s3://your-bucket-name/static-data/countries.csv
aws s3 cp categories.csv s3://your-bucket-name/static-data/categories.csv
```

CSV files should have headers matching table column names.

### Re-running Initialization

The initialization task checks for completion status. To re-run:

1. Connect to the database
2. Delete or update the `db_init_status` table
3. Manually trigger the ECS task:

```bash
aws ecs run-task \
  --cluster docmp-cluster \
  --task-definition docmp-db-init \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}"
```

## 🔧 Configuration Reference

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for resources | - |
| `project_name` | Project name for resource naming | - |
| `vpc_cidr` | CIDR block for VPC | - |
| `rds_instance_class` | RDS instance type | - |
| `msk_instance_type` | MSK broker instance type | - |
| `redis_node_type` | Redis node type | - |
| `ecs_task_cpu` | CPU units for ECS tasks | - |
| `ecs_task_memory` | Memory for ECS tasks (MB) | - |

See `variables.tf` for complete list.

## 📦 Module Structure

```
.
├── main.tf                      # Root module
├── variables.tf                 # Variable definitions
├── outputs.tf                   # Output definitions
├── provider.tf                  # Provider configuration
├── terraform.tfvars.example     # Example variables
├── modules/
│   ├── networking/              # VPC, subnets, security groups
│   ├── alb/                     # Application Load Balancer
│   ├── rds/                     # PostgreSQL databases
│   ├── msk/                     # Kafka cluster
│   ├── redis/                   # Redis cluster
│   ├── ecs/                     # ECS cluster and services
│   ├── s3/                      # S3 bucket
│   └── iam/                     # IAM roles and policies
├── scripts/
│   ├── db-init.sh               # Database initialization script
│   └── Dockerfile.db-init       # Docker image for DB init
└── .github/
    └── workflows/
        └── terraform.yml        # CI/CD pipeline
```

## 🔐 Security Considerations

- All sensitive data stored in AWS Secrets Manager
- Security groups follow least privilege principle
- Encryption at rest enabled for all data stores
- Encryption in transit enabled (TLS)
- Private subnets for databases and application servers
- No public access to databases

## 📈 Monitoring and Logging

- CloudWatch Logs enabled for:
  - ECS tasks
  - RDS PostgreSQL
  - MSK brokers
  - Redis
- Container Insights enabled for ECS
- Log retention: 7 days (configurable)

## 🔄 PostgreSQL Active-Active Setup

### Infrastructure Level

Terraform provisions:
- Two independent PostgreSQL instances
- Logical replication enabled via parameter group
- Both instances in different availability zones
- Separate endpoints for each instance

### What's NOT Included

- Replication slot configuration
- Publication/subscription setup
- pgactive installation
- Application-level failover logic

These must be configured separately after infrastructure deployment.

## 🛠️ Maintenance

### Updating Infrastructure

1. Modify `terraform.tfvars`
2. Run `terraform plan` to review changes
3. Run `terraform apply` to apply changes

### Scaling

Adjust these variables in `terraform.tfvars`:

- `ecs_desired_count`: Number of ECS tasks
- `rds_instance_class`: Database instance size
- `msk_number_of_broker_nodes`: Kafka broker count
- `redis_num_cache_nodes`: Redis node count

### Backup and Recovery

- RDS automated backups: 7 days retention (configurable)
- Point-in-time recovery enabled
- S3 versioning enabled for scripts and data

## 🐛 Troubleshooting

### Database Connection Issues

```bash
# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxx

# Test connectivity from ECS task
aws ecs execute-command --cluster docmp-cluster \
  --task task-id \
  --container docmp-container \
  --interactive \
  --command "/bin/bash"
```

### ECS Task Failures

```bash
# View logs
aws logs tail /ecs/docmp --follow

# Describe task
aws ecs describe-tasks --cluster docmp-cluster --tasks task-id
```

### Terraform State Issues

```bash
# Refresh state
terraform refresh

# Import existing resource
terraform import module.rds.aws_db_instance.primary db-instance-id
```

## 📝 Important Notes

1. **One-Time Initialization**: Database initialization runs only once. The script checks for completion status.

2. **No Replication Configuration**: PostgreSQL replication must be configured manually after infrastructure deployment.

3. **Single Environment**: This setup is for a single environment. For multiple environments, duplicate the configuration with different tfvars files.

4. **Cost Optimization**: Review instance sizes and adjust based on actual usage.

5. **SSL Certificates**: Add SSL certificate ARN to enable HTTPS on ALB.

## 🤝 Contributing

1. Create a feature branch
2. Make changes
3. Test with `terraform plan`
4. Submit pull request
5. GitHub Actions will validate changes

## 📄 License

[Add your license here]

## 📞 Support

For issues or questions:
- Create an issue in this repository
- Contact: [your-contact-info]

## 🔗 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [PostgreSQL Logical Replication](https://www.postgresql.org/docs/current/logical-replication.html)
- [MSK Documentation](https://docs.aws.amazon.com/msk/)