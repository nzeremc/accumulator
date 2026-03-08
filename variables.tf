# General Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state storage"
  type        = string
}

# Networking Configuration
variable "create_networking" {
  description = "Toggle to create networking resources (true) or use existing VPC (false)"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for VPC (only used when create_networking is true)"
  type        = string
  default     = ""
}

variable "availability_zones" {
  description = "List of availability zones (only used when create_networking is true)"
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (only used when create_networking is true)"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (only used when create_networking is true)"
  type        = list(string)
  default     = []
}

# Existing VPC Configuration (used when create_networking is false)
variable "existing_vpc_id" {
  description = "ID of existing VPC (required when create_networking is false)"
  type        = string
  default     = ""
}

variable "existing_private_subnet_ids" {
  description = "List of existing private subnet IDs (required when create_networking is false)"
  type        = list(string)
  default     = []
}

variable "existing_public_subnet_ids" {
  description = "List of existing public subnet IDs (required when create_networking is false)"
  type        = list(string)
  default     = []
}

variable "existing_rds_security_group_id" {
  description = "ID of existing RDS security group (required when create_networking is false)"
  type        = string
  default     = ""
}

variable "existing_msk_security_group_id" {
  description = "ID of existing MSK security group (required when create_networking is false)"
  type        = string
  default     = ""
}

variable "existing_redis_security_group_id" {
  description = "ID of existing Redis security group (required when create_networking is false)"
  type        = string
  default     = ""
}

variable "existing_alb_security_group_id" {
  description = "ID of existing ALB security group (required when create_networking is false)"
  type        = string
  default     = ""
}

variable "existing_ecs_tasks_security_group_id" {
  description = "ID of existing ECS tasks security group (required when create_networking is false)"
  type        = string
  default     = ""
}

# RDS PostgreSQL Configuration
variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
}

variable "rds_database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "docmp"
}

variable "rds_master_username" {
  description = "Master username for RDS"
  type        = string
  sensitive   = true
}

variable "rds_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = true
}

# MSK Configuration
variable "msk_instance_type" {
  description = "MSK broker instance type"
  type        = string
}

variable "msk_number_of_broker_nodes" {
  description = "Number of broker nodes in MSK cluster"
  type        = number
}

variable "msk_kafka_version" {
  description = "Kafka version for MSK"
  type        = string
}

variable "msk_ebs_volume_size" {
  description = "EBS volume size for MSK brokers in GB"
  type        = number
}

# Redis Configuration
variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes"
  type        = number
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
}

variable "redis_parameter_group_family" {
  description = "Redis parameter group family"
  type        = string
}

# ECS Configuration
variable "ecs_task_cpu" {
  description = "CPU units for ECS task"
  type        = string
}

variable "ecs_task_memory" {
  description = "Memory for ECS task in MB"
  type        = string
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
}

variable "ecs_container_port" {
  description = "Container port for ECS service"
  type        = number
  default     = 8080
}

# Database Initialization Configuration
variable "db_init_script_s3_key" {
  description = "S3 key for database initialization SQL script"
  type        = string
  default     = "init/schema.sql"
}

variable "db_init_static_files_prefix" {
  description = "S3 prefix for static data files"
  type        = string
  default     = "static-data/"
}

variable "enable_db_initialization" {
  description = "Enable one-time database initialization"
  type        = bool
  default     = true
}

# Load Balancer Configuration
variable "alb_health_check_path" {
  description = "Health check path for ALB target group"
  type        = string
  default     = "/health"
}

variable "alb_health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "alb_health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "alb_healthy_threshold" {
  description = "Number of consecutive health checks successes required"
  type        = number
  default     = 2
}

variable "alb_unhealthy_threshold" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 3
}

# S3 Configuration
variable "s3_bucket_name" {
  description = "Name for S3 bucket (must be globally unique)"
  type        = string
}

variable "s3_versioning_enabled" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}