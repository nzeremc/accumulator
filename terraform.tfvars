# ============================================================================
# DOCMP Active-Active Distributed System Configuration
# ============================================================================
# This file contains all client-configurable settings for the infrastructure.
# Update these values according to your requirements before deployment.
# ============================================================================

# ----------------------------------------------------------------------------
# GENERAL CONFIGURATION
# ----------------------------------------------------------------------------
aws_region   = "ap-south-1"  # AWS region for deployment
project_name = "docmp"       # Project name (used for resource naming)
environment  = "production"  # Environment name (dev/staging/production)

# ----------------------------------------------------------------------------
# TERRAFORM STATE STORAGE
# ----------------------------------------------------------------------------
# S3 bucket for storing Terraform state files
# IMPORTANT: This bucket must exist before running terraform init
terraform_state_bucket = "docmp-terraform-state-2101"

# ----------------------------------------------------------------------------
# NETWORKING - EXISTING VPC CONFIGURATION
# ----------------------------------------------------------------------------
# Using existing VPC and subnets (as per requirements)
create_networking = false  # Set to false to use existing VPC

# Existing VPC ID
existing_vpc_id = "vpc-0bb67cf591eb840c2"

# Existing Private Subnets (for ECS, RDS, MSK, Redis)
existing_private_subnet_ids = [
  "subnet-0acefeb6a9825fb5b",
  "subnet-099ac7c0bf429081f",
  "subnet-08d141bf2f954a835",
  "subnet-06dfb8065d398498c"
]

# Existing Public Subnets (for ALB)
existing_public_subnet_ids = [
  "subnet-0acefeb6a9825fb5b",
  "subnet-099ac7c0bf429081f"
]

# Existing Security Groups
existing_rds_security_group_id       = "sg-0473a57c1f7399590"  # RDS PostgreSQL
existing_msk_security_group_id       = "sg-0d4d549ec46711a91"  # MSK (Kafka)
existing_redis_security_group_id     = "sg-0d4a77df4ebf43fa2"  # Redis
existing_alb_security_group_id       = "sg-0e2fc451c79b07905"  # Application Load Balancer
existing_ecs_tasks_security_group_id = "sg-0473a57c1f7399590"  # ECS Tasks

# ----------------------------------------------------------------------------
# DATABASE CONFIGURATION (RDS PostgreSQL Active-Active)
# ----------------------------------------------------------------------------
# Database credentials are pulled from AWS Secrets Manager: dev/docmp/db
# No password configuration needed here

rds_instance_class    = "db.t3.micro"  # Instance type (t3.micro=dev, t3.large+=prod)
rds_allocated_storage = 20             # Storage in GB (20=dev, 100+=prod)
rds_engine_version    = "18.3"         # PostgreSQL version
rds_database_name     = "docmp"        # Database name
rds_master_username   = "docmp_admin"  # Master username

# High Availability Settings
rds_backup_retention_period = 0      # Backup retention days (0=dev, 7+=prod)
rds_multi_az                = false  # Multi-AZ deployment (false=dev, true=prod)

# ----------------------------------------------------------------------------
# KAFKA CONFIGURATION (MSK - System Memory)
# ----------------------------------------------------------------------------
# Kafka acts as the system's "memory" for transaction buffering

msk_instance_type          = "kafka.m5.large"  # Broker instance type
msk_number_of_broker_nodes = 3                 # Number of brokers (min 3 for HA)
msk_kafka_version          = "3.5.1"           # Kafka version
msk_ebs_volume_size        = 100               # Storage per broker in GB

# ----------------------------------------------------------------------------
# REDIS CONFIGURATION (Regional Memory - Ultra-Low Latency)
# ----------------------------------------------------------------------------
# Redis provides < 5ms read latency for immediate GET requests

redis_node_type              = "cache.t3.medium"  # Node type (t3.medium=dev, t3.large+=prod)
redis_num_cache_nodes        = 2                  # Number of nodes (2=HA)
redis_engine_version         = "7.0"              # Redis version
redis_parameter_group_family = "redis7"           # Parameter group family

# ----------------------------------------------------------------------------
# APPLICATION RUNTIME (ECS Fargate)
# ----------------------------------------------------------------------------
# Fargate provides serverless container execution for the API application

ecs_task_cpu       = "1024"  # CPU units (1024 = 1 vCPU)
ecs_task_memory    = "2048"  # Memory in MB (2048 = 2 GB)
ecs_desired_count  = 2       # Number of tasks to run
ecs_container_port = 8080    # Application port

# ----------------------------------------------------------------------------
# LOAD BALANCER CONFIGURATION
# ----------------------------------------------------------------------------
# Health check settings for the Application Load Balancer

alb_health_check_path     = "/health"  # Health check endpoint
alb_health_check_interval = 30         # Seconds between health checks
alb_health_check_timeout  = 5          # Health check timeout in seconds
alb_healthy_threshold     = 2          # Consecutive successes to mark healthy
alb_unhealthy_threshold   = 3          # Consecutive failures to mark unhealthy

# ----------------------------------------------------------------------------
# STORAGE CONFIGURATION (S3)
# ----------------------------------------------------------------------------
# S3 bucket for database initialization scripts and static data

s3_bucket_name        = "docmp-data-bucket-unique-name"  # Must be globally unique
s3_versioning_enabled = true                             # Enable versioning

# ----------------------------------------------------------------------------
# RESOURCE TAGGING
# ----------------------------------------------------------------------------
# Tags applied to all resources for organization and cost tracking

additional_tags = {
  Owner      = "DevOps Team"
  CostCenter = "Engineering"
  Compliance = "HIPAA"
}

# ============================================================================
# DEPLOYMENT NOTES
# ============================================================================
# 1. Database credentials are automatically retrieved from Secrets Manager
#    Secret name: dev/docmp/db
#
# 2. Redis Global Datastore requires two-stage deployment:
#    - Stage 1: Deploy with current settings
#    - Stage 2: Enable global_datastore in modules/redis/variables.tf
#
# 3. After infrastructure deployment, build and push the application:
#    cd app/
#    docker build -t docmp-app:latest .
#    docker tag docmp-app:latest <ECR_REPO>:latest
#    docker push <ECR_REPO>:latest
#
# 4. Cost estimates:
#    - Development: ~$200-300/month
#    - Production: ~$800-1200/month (single region)
#
# 5. For production, consider:
#    - rds_instance_class = "db.t3.large" or higher
#    - rds_multi_az = true
#    - rds_backup_retention_period = 7 or higher
#    - redis_node_type = "cache.t3.large" or higher
#    - ecs_desired_count = 3 or higher with auto-scaling
# ============================================================================