# General Configuration
aws_region   = "ap-south-1" # Mumbai region
project_name = "docmp"
environment  = "production"

# Terraform Backend Configuration
# S3 bucket for storing Terraform state
terraform_state_bucket = "docmp-terraform-state-2101"

# Networking Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# RDS PostgreSQL Configuration (Active-Active Infrastructure)
# Note: Password is auto-generated and stored in AWS Secrets Manager
rds_instance_class          = "db.t3.micro"  # Free tier: db.t2.micro or db.t3.micro, Production: db.t3.large or higher
rds_allocated_storage       = 20             # Free tier: max 20GB, Production: increase as needed
rds_engine_version          = "14.10"        # Stable version available in most regions
rds_database_name           = "docmp"
rds_master_username         = "docmp_admin"
rds_backup_retention_period = 0              # Set to 0 for free tier testing, increase for production (1-35 days)
rds_multi_az                = false          # Free tier: false, Production: true for high availability

# MSK (Kafka) Configuration
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
ecs_task_cpu       = "1024"
ecs_task_memory    = "2048"
ecs_desired_count  = 2
ecs_container_port = 8080
# Note: ECR repositories are created automatically by Terraform
# Container images will use: <account-id>.dkr.ecr.<region>.amazonaws.com/docmp-app:latest

# Database Initialization Configuration
db_init_script_s3_key       = "init/schema.sql"
db_init_static_files_prefix = "static-data/"
enable_db_initialization    = true

# Load Balancer Configuration
alb_health_check_path     = "/health"
alb_health_check_interval = 30
alb_health_check_timeout  = 5
alb_healthy_threshold     = 2
alb_unhealthy_threshold   = 3

# S3 Configuration
s3_bucket_name        = "docmp-data-bucket-unique-name"
s3_versioning_enabled = true

# Additional Tags
additional_tags = {
  Owner      = "DevOps Team"
  CostCenter = "Engineering"
  Compliance = "HIPAA"
}