variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for ECS task"
  type        = string
}

variable "task_memory" {
  description = "Memory for ECS task in MB"
  type        = string
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
}

variable "container_image" {
  description = "Docker image for ECS container"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "execution_role_arn" {
  description = "ARN of ECS task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of ECS task role"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of ALB target group"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of ALB listener"
  type        = string
}

variable "db_primary_host" {
  description = "Primary database host"
  type        = string
}

variable "db_secondary_host" {
  description = "Secondary database host"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of database credentials secret"
  type        = string
  sensitive   = false
}

variable "redis_host" {
  description = "Redis host"
  type        = string
}

variable "redis_secret_arn" {
  description = "ARN of Redis AUTH token secret"
  type        = string
  sensitive   = false
}

variable "kafka_brokers" {
  description = "Kafka bootstrap brokers"
  type        = string
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "db_init_image" {
  description = "Docker image for DB initialization task"
  type        = string
}

variable "pgactive_image" {
  description = "Docker image for PGActive replication setup task"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name containing SQL scripts and data files"
  type        = string
}