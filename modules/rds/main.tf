# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name_prefix = "${var.project_name}-db-subnet-group-"
  subnet_ids  = var.private_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-subnet-group"
    }
  )
}

# DB Parameter Group with logical replication enabled
resource "aws_db_parameter_group" "postgres" {
  name_prefix = "${var.project_name}-postgres-pg-"
  family      = "postgres${split(".", var.engine_version)[0]}"
  description = "PostgreSQL parameter group with logical replication enabled"

  # Enable logical replication at infrastructure level (static parameter - requires reboot)
  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "max_replication_slots"
    value        = "10"
    apply_method = "pending-reboo"
  }

  parameter {
    name         = "max_wal_senders"
    value        = "10"
    apply_method = "pending-reboo"
  }

  parameter {
    name         = "wal_sender_timeout"
    value        = "0"
    apply_method = "pending-reboo"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-postgres-parameter-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Random password for master user
resource "random_password" "master" {
  length  = 32
  special = true
}

# Store master password in Secrets Manager
resource "aws_secretsmanager_secret" "db_master" {
  name_prefix             = "${var.project_name}-db-master-"
  description             = "Master credentials for RDS PostgreSQL"
  recovery_window_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-master-secret"
    }
  )
}

resource "aws_secretsmanager_secret_version" "db_master" {
  secret_id = aws_secretsmanager_secret.db_master.id
  secret_string = jsonencode({
    username                       = var.master_username
    password                       = var.master_password != "" ? var.master_password : random_password.master.result
    engine                         = "postgres"
    host_primary                   = aws_db_instance.primary.address
    host_secondary                 = aws_db_instance.secondary.address
    port                           = aws_db_instance.primary.port
    dbname                         = var.database_name
    dbInstanceIdentifier_primary   = aws_db_instance.primary.id
    dbInstanceIdentifier_secondary = aws_db_instance.secondary.id
  })
}

# Primary RDS Instance
resource "aws_db_instance" "primary" {
  identifier_prefix = "${var.project_name}-postgres-primary-"

  engine            = "postgres"
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.database_name
  username = var.master_username
  password = var.master_password != "" ? var.master_password : random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  parameter_group_name   = aws_db_parameter_group.postgres.name

  multi_az                = var.multi_az
  publicly_accessible     = false
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-postgres-primary-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  deletion_protection = true

  auto_minor_version_upgrade = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-postgres-primary"
      Role = "Primary"
    }
  )

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
      password
    ]
  }
}

# Secondary RDS Instance (Active-Active Infrastructure)
resource "aws_db_instance" "secondary" {
  identifier_prefix = "${var.project_name}-postgres-secondary-"

  engine            = "postgres"
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.database_name
  username = var.master_username
  password = var.master_password != "" ? var.master_password : random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  parameter_group_name   = aws_db_parameter_group.postgres.name

  multi_az                = var.multi_az
  publicly_accessible     = false
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "tue:04:00-tue:05:00"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-postgres-secondary-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  deletion_protection = true

  auto_minor_version_upgrade = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-postgres-secondary"
      Role = "Secondary"
    }
  )

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
      password
    ]
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "primary_postgresql" {
  name              = "/aws/rds/instance/${aws_db_instance.primary.identifier}/postgresql"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-primary-postgresql-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "secondary_postgresql" {
  name              = "/aws/rds/instance/${aws_db_instance.secondary.identifier}/postgresql"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-secondary-postgresql-logs"
    }
  )
}