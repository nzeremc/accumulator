# Local variables
locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.additional_tags
  )

  # Conditionally use networking module outputs or existing VPC details
  vpc_id                      = var.create_networking ? module.networking[0].vpc_id : var.existing_vpc_id
  private_subnet_ids          = var.create_networking ? module.networking[0].private_subnet_ids : var.existing_private_subnet_ids
  public_subnet_ids           = var.create_networking ? module.networking[0].public_subnet_ids : var.existing_public_subnet_ids
  rds_security_group_id       = var.create_networking ? module.networking[0].rds_security_group_id : var.existing_rds_security_group_id
  msk_security_group_id       = var.create_networking ? module.networking[0].msk_security_group_id : var.existing_msk_security_group_id
  redis_security_group_id     = var.create_networking ? module.networking[0].redis_security_group_id : var.existing_redis_security_group_id
  alb_security_group_id       = var.create_networking ? module.networking[0].alb_security_group_id : var.existing_alb_security_group_id
  ecs_tasks_security_group_id = var.create_networking ? module.networking[0].ecs_tasks_security_group_id : var.existing_ecs_tasks_security_group_id
}

# Generate random password for RDS
resource "random_password" "rds_master_password" {
  length  = 16
  special = true
  # Exclude characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store RDS password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "rds_master_password" {
  name_prefix             = "${var.project_name}-rds-master-password-"
  description             = "Master password for RDS PostgreSQL instances"
  recovery_window_in_days = 7

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "rds_master_password" {
  secret_id = aws_secretsmanager_secret.rds_master_password.id
  secret_string = jsonencode({
    username = var.rds_master_username
    password = random_password.rds_master_password.result
    engine   = "postgres"
    port     = 5432
    dbname   = var.rds_database_name
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Networking Module (conditionally created)
module "networking" {
  count  = var.create_networking ? 1 : 0
  source = "./modules/networking"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  container_port       = var.ecs_container_port
  aws_region           = var.aws_region

  tags = local.common_tags
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  project_name       = var.project_name
  bucket_name        = var.s3_bucket_name
  versioning_enabled = var.s3_versioning_enabled

  tags = local.common_tags
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name

  tags = local.common_tags
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  project_name            = var.project_name
  engine_version          = var.rds_engine_version
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  database_name           = var.rds_database_name
  master_username         = var.rds_master_username
  master_password         = random_password.rds_master_password.result
  backup_retention_period = var.rds_backup_retention_period
  multi_az                = var.rds_multi_az
  private_subnet_ids      = local.private_subnet_ids
  security_group_id       = local.rds_security_group_id
  s3_bucket_name          = module.s3.bucket_name

  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name  = var.project_name
  s3_bucket_arn = module.s3.bucket_arn
  db_secret_arn = aws_secretsmanager_secret.rds_master_password.arn

  tags = local.common_tags
}

# MSK Module
module "msk" {
  source = "./modules/msk"

  project_name           = var.project_name
  kafka_version          = var.msk_kafka_version
  instance_type          = var.msk_instance_type
  number_of_broker_nodes = var.msk_number_of_broker_nodes
  ebs_volume_size        = var.msk_ebs_volume_size
  private_subnet_ids     = local.private_subnet_ids
  security_group_id      = local.msk_security_group_id

  tags = local.common_tags
}

# Redis Module
module "redis" {
  source = "./modules/redis"

  project_name           = var.project_name
  engine_version         = var.redis_engine_version
  node_type              = var.redis_node_type
  num_cache_nodes        = var.redis_num_cache_nodes
  parameter_group_family = var.redis_parameter_group_family
  private_subnet_ids     = local.private_subnet_ids
  security_group_id      = local.redis_security_group_id

  tags = local.common_tags
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  vpc_id                = local.vpc_id
  public_subnet_ids     = local.public_subnet_ids
  security_group_id     = local.alb_security_group_id
  container_port        = var.ecs_container_port
  health_check_path     = var.alb_health_check_path
  health_check_interval = var.alb_health_check_interval
  health_check_timeout  = var.alb_health_check_timeout
  healthy_threshold     = var.alb_healthy_threshold
  unhealthy_threshold   = var.alb_unhealthy_threshold
  certificate_arn       = "" # Add SSL certificate ARN if available

  tags = local.common_tags
}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api_gateway"

  project_name           = var.project_name
  alb_arn                = module.alb.alb_arn
  alb_dns_name           = module.alb.alb_dns_name
  stage_name             = var.environment
  throttling_burst_limit = 5000
  throttling_rate_limit  = 10000
  waf_rate_limit         = 2000

  tags = local.common_tags

  depends_on = [module.alb]
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"

  project_name       = var.project_name
  aws_region         = var.aws_region
  task_cpu           = var.ecs_task_cpu
  task_memory        = var.ecs_task_memory
  desired_count      = var.ecs_desired_count
  container_image    = "${module.ecr.app_repository_url}:latest"
  container_port     = var.ecs_container_port
  execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  private_subnet_ids = local.private_subnet_ids
  security_group_id  = local.ecs_tasks_security_group_id
  target_group_arn   = module.alb.target_group_arn
  alb_listener_arn   = module.alb.http_listener_arn
  db_primary_host    = module.rds.primary_instance_address
  db_secondary_host  = module.rds.secondary_instance_address
  db_port            = module.rds.database_port
  db_name            = module.rds.database_name
  db_secret_arn      = nonsensitive(module.rds.db_secret_arn)
  redis_host         = module.redis.primary_endpoint_address
  redis_secret_arn   = nonsensitive(module.redis.auth_token_secret_arn)
  kafka_brokers      = module.msk.bootstrap_brokers_tls
  health_check_path  = var.alb_health_check_path
  db_init_image      = "${module.ecr.db_init_repository_url}:latest"
  pgactive_image     = "${module.ecr.pgactive_repository_url}:latest"
  s3_bucket_name     = module.s3.bucket_name

  tags = local.common_tags

  depends_on = [module.rds, module.redis, module.msk]
}