# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-redis-subnet-group"
    }
  )
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "main" {
  name   = "${var.project_name}-redis-params"
  family = var.parameter_group_family

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-redis-parameter-group"
    }
  )
}

# ElastiCache Replication Group (Redis Cluster with High Availability)
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project_name}-redis"
  description          = "Redis cluster for ${var.project_name}"
  
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.main.name
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [var.security_group_id]

  # High Availability Configuration
  automatic_failover_enabled = var.num_cache_nodes > 1 ? true : false
  multi_az_enabled          = var.num_cache_nodes > 1 ? true : false

  # Backup Configuration
  snapshot_retention_limit = 5
  snapshot_window         = "03:00-05:00"
  maintenance_window      = "sun:05:00-sun:07:00"

  # Encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                = random_password.redis_auth.result

  # Logging
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-redis-cluster"
    }
  )
}

# Random password for Redis AUTH
resource "random_password" "redis_auth" {
  length  = 32
  special = false
}

# Store Redis AUTH token in Secrets Manager
resource "aws_secretsmanager_secret" "redis_auth" {
  name_prefix             = "${var.project_name}-redis-auth-"
  description             = "Redis AUTH token"
  recovery_window_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-redis-auth-secret"
    }
  )
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id = aws_secretsmanager_secret.redis_auth.id
  secret_string = jsonencode({
    auth_token              = random_password.redis_auth.result
    primary_endpoint        = aws_elasticache_replication_group.main.primary_endpoint_address
    reader_endpoint         = aws_elasticache_replication_group.main.reader_endpoint_address
    configuration_endpoint  = aws_elasticache_replication_group.main.configuration_endpoint_address
    port                    = 6379
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "redis_slow_log" {
  name              = "/aws/elasticache/${var.project_name}/slow-log"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-redis-slow-log"
    }
  )
}

resource "aws_cloudwatch_log_group" "redis_engine_log" {
  name              = "/aws/elasticache/${var.project_name}/engine-log"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-redis-engine-log"
    }
  )
}