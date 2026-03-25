# DOCMP Active-Active Distributed System

Complete AWS infrastructure for an Active-Active distributed system with API Gateway, Kafka buffering, Redis caching, and PostgreSQL replication.

## 🏗️ System Architecture

```
Client → API Gateway → VPC Link → ALB → ECS Fargate (FastAPI App)
                                           ↓
                                    ┌──────┴──────┐
                                    ↓             ↓
                              Kafka (MSK)    Redis Cache
                              (System         (Regional
                               Memory)         Memory)
                                    ↓             ↓
                            Pending Updates   Database
                                Table         (RDS PostgreSQL)
                            (Visibility Gap)  (Active-Active)
```

### Key Components

1. **API Gateway** - Request entry point with rate limiting and WAF protection
2. **Application Load Balancer** - Traffic distribution to ECS tasks
3. **ECS Fargate** - Serverless container runtime for the API application
4. **MSK (Kafka)** - System "memory" for transaction buffering and cross-region sync
5. **Redis (ElastiCache)** - Regional memory for ultra-low latency reads
6. **RDS PostgreSQL** - Active-Active database (source of truth)
7. **Pending Updates Table** - Visibility gap solution when Redis is unavailable

## 📋 Prerequisites

- AWS Account with appropriate permissions
- Existing VPC and subnets (specified in requirements)
- Existing database credentials in Secrets Manager: `dev/docmp/db`
- Terraform >= 1.0
- AWS CLI configured
- Docker (for building application images)

## 🚀 Quick Start

### 1. Configure Existing Infrastructure

Edit `terraform.tfvars` with your existing VPC details:

```hcl
# Use existing VPC (already configured)
create_networking = false
existing_vpc_id = "vpc-0bb67cf591eb840c2"
existing_private_subnet_ids = [
  "subnet-0acefeb6a9825fb5b",
  "subnet-099ac7c0bf429081f",
  "subnet-08d141bf2f954a835",
  "subnet-06dfb8065d398498c"
]
```

### 2. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review changes
terraform plan

# Deploy infrastructure
terraform apply
```

### 3. Build and Push Application

```bash
# Get ECR repository URL
ECR_REPO=$(terraform output -raw ecr_app_repository_url)
AWS_REGION=$(terraform output -raw aws_region)

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ECR_REPO}

# Build and push application
cd app
docker build -t docmp-app:latest .
docker tag docmp-app:latest ${ECR_REPO}:latest
docker push ${ECR_REPO}:latest
```

### 4. Initialize Database

```bash
# Run database initialization task
aws ecs run-task \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --task-definition docmp-db-init \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[...],securityGroups=[...]}"
```

## 📁 Project Structure

```
aws-tf/
├── main.tf                          # Root module - integrates all components
├── variables.tf                     # Variable definitions
├── outputs.tf                       # Output definitions
├── provider.tf                      # AWS provider configuration
├── terraform.tfvars                 # Your configuration (VPC, subnets, etc.)
│
├── modules/                         # Terraform modules
│   ├── api_gateway/                 # ✨ NEW: API Gateway with VPC Link
│   │   ├── main.tf                  # API Gateway, WAF, rate limiting
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── alb/                         # Application Load Balancer
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ecs/                         # ECS Fargate cluster and services
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── rds/                         # PostgreSQL Active-Active
│   │   ├── main.tf                  # ✨ UPDATED: Includes Pending Updates Table SQL
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── redis/                       # Redis with Global Datastore
│   │   ├── main.tf                  # ✨ UPDATED: Global Datastore support
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── msk/                         # Kafka cluster
│   │   ├── main.tf                  # ✨ UPDATED: Cross-region mirroring config
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── iam/                         # IAM roles and policies
│   │   ├── main.tf                  # ✨ UPDATED: MSK and Redis permissions
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── federated_role.tf
│   │
│   ├── ecr/                         # Container registries
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── s3/                          # S3 bucket for data
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── networking/                  # VPC, subnets, security groups
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── vpc_endpoints.tf
│
├── app/                             # ✨ NEW: FastAPI Application
│   ├── main.py                      # API application (378 lines)
│   ├── requirements.txt             # Python dependencies
│   └── Dockerfile                   # Container definition
│
├── scripts/                         # Database initialization scripts
│   ├── db-init.sh                   # Database initialization script
│   ├── Dockerfile.db-init           # DB init container
│   ├── pgactive-setup.sh            # Active-Active replication setup
│   ├── Dockerfile.pgactive          # PGActive container
│   └── schema.sql.example           # Example schema
│
├── data-files/                      # Database data files
│   ├── init/
│   │   ├── README.md                # Instructions for schema files
│   │   └── schema.sql               # Your database schema
│   └── static-data/
│       ├── README.md                # Instructions for static data
│       └── *.csv                    # CSV files for data loading
│
└── .github/
    └── workflows/
        └── terraform.yml            # CI/CD pipeline
```

## 🔧 Configuration

### Required Configuration in terraform.tfvars

```hcl
# General
aws_region   = "ap-south-1"
project_name = "docmp"
environment  = "production"

# Existing VPC (REQUIRED)
create_networking = false
existing_vpc_id = "vpc-0bb67cf591eb840c2"
existing_private_subnet_ids = [
  "subnet-0acefeb6a9825fb5b",
  "subnet-099ac7c0bf429081f",
  "subnet-08d141bf2f954a835",
  "subnet-06dfb8065d398498c"
]
existing_public_subnet_ids = [
  "subnet-0acefeb6a9825fb5b",
  "subnet-099ac7c0bf429081f"
]

# Security Groups (REQUIRED)
existing_rds_security_group_id       = "sg-0473a57c1f7399590"
existing_msk_security_group_id       = "sg-0d4d549ec46711a91"
existing_redis_security_group_id     = "sg-0d4a77df4ebf43fa2"
existing_alb_security_group_id       = "sg-0e2fc451c79b07905"
existing_ecs_tasks_security_group_id = "sg-0473a57c1f7399590"

# Database (uses existing credentials from Secrets Manager: dev/docmp/db)
rds_instance_class    = "db.t3.micro"    # Dev: db.t3.micro, Prod: db.t3.large+
rds_allocated_storage = 20               # GB
rds_database_name     = "docmp"
rds_master_username   = "docmp_admin"

# Kafka
msk_instance_type          = "kafka.m5.large"
msk_number_of_broker_nodes = 3

# Redis
redis_node_type       = "cache.t3.medium"
redis_num_cache_nodes = 2

# ECS
ecs_task_cpu      = "1024"  # 1 vCPU
ecs_task_memory   = "2048"  # 2 GB
ecs_desired_count = 2       # Number of tasks
```

## 🎯 Key Features

### 1. API Gateway with Request Buffering
- **Location:** `modules/api_gateway/`
- Rate limiting: 10,000 requests/second, 5,000 burst
- WAF protection: 2,000 requests per 5 minutes per IP
- IAM authentication
- CloudWatch logging and X-Ray tracing

### 2. Kafka System Memory
- **Location:** `modules/msk/`
- All POST/PUT requests immediately buffered to Kafka
- Cross-region mirroring support
- Compression enabled (snappy)
- 3 brokers across 3 availability zones

### 3. Redis Regional Memory
- **Location:** `modules/redis/`
- Ultra-low latency reads (< 5ms)
- Global Datastore support for Active-Active across regions
- Multi-AZ with automatic failover
- TLS encryption and AUTH token

### 4. Pending Updates Table
- **Location:** `modules/rds/main.tf` (SQL schema)
- Tracks in-flight transactions when Redis is unavailable
- Bridges visibility gap for immediate GET requests
- Automatic cleanup of old records (7 days)
- 6 indexes for performance

### 5. Three-Tier Read Strategy
- **Location:** `app/main.py`
- **Tier 1:** Redis cache (fastest, < 5ms)
- **Tier 2:** Pending Updates Table (< 20ms)
- **Tier 3:** Main database (< 50ms)

### 6. Active-Active Database
- **Location:** `modules/rds/`
- Two PostgreSQL instances with logical replication
- Bidirectional sync via pgactive
- Existing credentials: `dev/docmp/db` (Secrets Manager)

## 📡 API Endpoints

The FastAPI application (`app/main.py`) provides:

### Write Operations
```bash
# Create/Update entity (POST)
POST /api/update
{
  "entity_type": "user",
  "entity_id": "user123",
  "operation": "CREATE",
  "payload": { "name": "John", "email": "john@example.com" }
}

# Update entity (PUT)
PUT /api/update/{entity_id}
{
  "entity_type": "user",
  "entity_id": "user123",
  "operation": "UPDATE",
  "payload": { "name": "John Doe" }
}
```

### Read Operations
```bash
# Get entity (checks Redis → Pending Updates → Database)
GET /api/entity/{entity_type}/{entity_id}
```

### Health Check
```bash
# Health check (for ALB)
GET /health
```

## 🔐 Security

- **Encryption at Rest:** All data stores (RDS, MSK, Redis, S3)
- **Encryption in Transit:** TLS 1.2+ for all connections
- **IAM Authentication:** API Gateway, MSK
- **Secrets Manager:** Database and Redis credentials
- **VPC Isolation:** All resources in private subnets
- **Security Groups:** Least privilege access
- **WAF:** Rate limiting and IP filtering

## 📊 Monitoring

### CloudWatch Logs
- **API Gateway:** `/aws/apigateway/docmp`
- **ECS Application:** `/ecs/docmp`
- **Database Init:** `/ecs/docmp/db-init`
- **PGActive:** `/ecs/docmp/pgactive`
- **MSK:** `/aws/msk/docmp`
- **Redis:** `/aws/elasticache/docmp/slow-log`, `/aws/elasticache/docmp/engine-log`

### Key Metrics
- API Gateway: Request count, latency, errors
- ECS: CPU, memory, task count
- Kafka: Message throughput, consumer lag
- Redis: Cache hit rate, memory usage
- RDS: CPU, connections, replication lag

## 🚨 Important Notes

### 1. Redis Global Datastore (Two-Stage Deployment)
The Redis Global Datastore requires a two-stage deployment:

**Stage 1:** Initial deployment
```hcl
# In terraform.tfvars
# Leave enable_global_datastore commented out or set to false
```

**Stage 2:** Enable Global Datastore
```hcl
# In modules/redis/variables.tf, set:
enable_global_datastore = true
```
Then run `terraform apply` again.

### 2. Database Credentials
Uses existing credentials from Secrets Manager: `dev/docmp/db`

### 3. Pending Updates Table
The SQL schema is automatically stored in S3 during deployment:
- **Location:** `s3://{bucket}/init/pending_updates_table.sql`
- **Source:** `modules/rds/main.tf` (lines 195-280)

### 4. Application Deployment
After infrastructure deployment:
1. Build Docker image from `app/`
2. Push to ECR
3. ECS will automatically deploy the application

## 🔄 Data Flow

### Write Path (POST/PUT)
1. Client → API Gateway (rate limiting, WAF)
2. API Gateway → ALB → ECS Task
3. ECS Task → Kafka (immediate, durable write)
4. ECS Task → Redis (best-effort cache update)
5. If Redis fails → Pending Updates Table
6. Return 202 Accepted with transaction_id
7. Kafka consumers → Database (async)

### Read Path (GET)
1. Client → API Gateway → ALB → ECS Task
2. Check Redis cache (< 5ms)
   - If found → Return (X-Cache: HIT)
3. Check Pending Updates Table (< 20ms)
   - If found → Return (X-Source: PENDING)
4. Query main database (< 50ms)
   - If found → Return (X-Source: DATABASE)
5. If not found → 404

## 🛠️ Troubleshooting

### ECS Tasks Not Starting
```bash
# Check logs
aws logs tail /ecs/docmp --follow

# Check task status
aws ecs describe-tasks --cluster docmp-cluster --tasks <task-id>
```

### Redis Connection Issues
```bash
# Verify Redis cluster
aws elasticache describe-replication-groups --replication-group-id docmp-redis

# Check security group
aws ec2 describe-security-groups --group-ids sg-0d4a77df4ebf43fa2
```

### Kafka Connection Issues
```bash
# Verify MSK cluster
aws kafka describe-cluster --cluster-arn <cluster-arn>

# Check bootstrap brokers
aws kafka get-bootstrap-brokers --cluster-arn <cluster-arn>
```

### Database Connection Issues
```bash
# Test from ECS task
aws ecs execute-command --cluster docmp-cluster \
  --task <task-id> \
  --container docmp-container \
  --interactive \
  --command "/bin/bash"

# Then inside container:
psql -h <db-endpoint> -U docmp_admin -d docmp
```

## 📈 Scaling

### Horizontal Scaling
```bash
# Update ECS desired count
aws ecs update-service \
  --cluster docmp-cluster \
  --service docmp-service \
  --desired-count 4
```

### Vertical Scaling
Edit `terraform.tfvars`:
```hcl
# Increase task resources
ecs_task_cpu = "2048"     # 2 vCPU
ecs_task_memory = "4096"  # 4 GB

# Increase database
rds_instance_class = "db.t3.large"

# Increase Redis
redis_node_type = "cache.t3.large"
```

Then apply: `terraform apply`

## 💰 Cost Optimization

### Development Environment
- RDS: db.t3.micro, single-AZ
- Redis: cache.t3.micro, 1 node
- MSK: kafka.t3.small, 2 brokers
- ECS: 1 task
- **Estimated:** $200-300/month

### Production Environment
- RDS: db.t3.large, Multi-AZ
- Redis: cache.t3.medium, 2 nodes, Global Datastore
- MSK: kafka.m5.large, 3 brokers
- ECS: 2-6 tasks (auto-scaling)
- **Estimated:** $800-1200/month (single region)

## 📞 Support

For issues or questions:
1. Check CloudWatch logs for errors
2. Review security group configurations
3. Verify IAM permissions
4. Check Secrets Manager for credentials

## 🔗 Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [PostgreSQL Logical Replication](https://www.postgresql.org/docs/current/logical-replication.html)
- [MSK Documentation](https://docs.aws.amazon.com/msk/)
- [Redis Global Datastore](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Redis-Global-Datastore.html)