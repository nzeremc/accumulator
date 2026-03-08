# ECR Outputs
output "ecr_app_repository_url" {
  description = "URL of the application ECR repository"
  value       = module.ecr.app_repository_url
}

output "ecr_db_init_repository_url" {
  description = "URL of the DB init ECR repository"
  value       = module.ecr.db_init_repository_url
}

# Networking Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = local.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = local.private_subnet_ids
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

# RDS Outputs
output "rds_primary_endpoint" {
  description = "Primary RDS instance endpoint"
  value       = module.rds.primary_instance_endpoint
}

output "rds_secondary_endpoint" {
  description = "Secondary RDS instance endpoint"
  value       = module.rds.secondary_instance_endpoint
}

output "rds_database_name" {
  description = "Name of the database"
  value       = module.rds.database_name
}

output "rds_secret_arn" {
  description = "ARN of the RDS database credentials secret (from RDS module)"
  value       = module.rds.db_secret_arn
  sensitive   = true
}

output "rds_master_password_secret_arn" {
  description = "ARN of the auto-generated RDS master password in Secrets Manager"
  value       = aws_secretsmanager_secret.rds_master_password.arn
  sensitive   = true
}

output "rds_master_password_secret_name" {
  description = "Name of the auto-generated RDS master password secret"
  value       = aws_secretsmanager_secret.rds_master_password.name
}

# MSK Outputs
output "msk_bootstrap_brokers_tls" {
  description = "MSK bootstrap brokers (TLS)"
  value       = module.msk.bootstrap_brokers_tls
}

output "msk_zookeeper_connect_string" {
  description = "MSK Zookeeper connection string"
  value       = module.msk.zookeeper_connect_string
}

# Redis Outputs
output "redis_primary_endpoint" {
  description = "Redis primary endpoint"
  value       = module.redis.primary_endpoint_address
}

output "redis_auth_secret_arn" {
  description = "ARN of Redis AUTH token secret"
  value       = module.redis.auth_token_secret_arn
  sensitive   = true
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

# S3 Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3.bucket_arn
}

# Application URL
output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.alb.alb_dns_name}"
}

# Database Initialization
output "db_init_task_definition" {
  description = "ARN of the database initialization task definition"
  value       = var.enable_db_initialization ? aws_ecs_task_definition.db_init[0].arn : null
}