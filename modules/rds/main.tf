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
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "max_wal_senders"
    value        = "10"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "wal_sender_timeout"
    value        = "0"
    apply_method = "pending-reboot"
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
# CloudWatch log groups are automatically created by RDS when enabled_cloudwatch_logs_exports is set
# No need to explicitly create them as resources

# SQL script for Pending Updates Table
locals {
  pending_updates_table_sql = <<-SQL
    -- Pending Updates Table for visibility gap management
    -- This table tracks in-flight transactions when Redis is unavailable
    CREATE TABLE IF NOT EXISTS pending_updates (
      id BIGSERIAL PRIMARY KEY,
      transaction_id UUID NOT NULL UNIQUE,
      entity_type VARCHAR(100) NOT NULL,
      entity_id VARCHAR(255) NOT NULL,
      operation VARCHAR(20) NOT NULL CHECK (operation IN ('CREATE', 'UPDATE', 'DELETE')),
      payload JSONB NOT NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED')),
      kafka_topic VARCHAR(255) NOT NULL,
      kafka_partition INTEGER,
      kafka_offset BIGINT,
      created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
      completed_at TIMESTAMP WITH TIME ZONE,
      retry_count INTEGER NOT NULL DEFAULT 0,
      error_message TEXT,
      metadata JSONB
    );

    -- Indexes for efficient querying
    CREATE INDEX IF NOT EXISTS idx_pending_updates_transaction_id ON pending_updates(transaction_id);
    CREATE INDEX IF NOT EXISTS idx_pending_updates_entity ON pending_updates(entity_type, entity_id);
    CREATE INDEX IF NOT EXISTS idx_pending_updates_status ON pending_updates(status);
    CREATE INDEX IF NOT EXISTS idx_pending_updates_created_at ON pending_updates(created_at);
    CREATE INDEX IF NOT EXISTS idx_pending_updates_kafka_offset ON pending_updates(kafka_topic, kafka_partition, kafka_offset);

    -- Trigger to update updated_at timestamp
    CREATE OR REPLACE FUNCTION update_pending_updates_timestamp()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.updated_at = CURRENT_TIMESTAMP;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER trigger_update_pending_updates_timestamp
    BEFORE UPDATE ON pending_updates
    FOR EACH ROW
    EXECUTE FUNCTION update_pending_updates_timestamp();

    -- Function to clean up old completed records (older than 7 days)
    CREATE OR REPLACE FUNCTION cleanup_old_pending_updates()
    RETURNS INTEGER AS $$
    DECLARE
      deleted_count INTEGER;
    BEGIN
      DELETE FROM pending_updates
      WHERE status = 'COMPLETED'
        AND completed_at < CURRENT_TIMESTAMP - INTERVAL '7 days';
      GET DIAGNOSTICS deleted_count = ROW_COUNT;
      RETURN deleted_count;
    END;
    $$ LANGUAGE plpgsql;

    -- Create a view for monitoring pending transactions
    CREATE OR REPLACE VIEW v_pending_updates_summary AS
    SELECT
      status,
      entity_type,
      COUNT(*) as count,
      MIN(created_at) as oldest_transaction,
      MAX(created_at) as newest_transaction,
      AVG(retry_count) as avg_retry_count
    FROM pending_updates
    WHERE status IN ('PENDING', 'PROCESSING')
    GROUP BY status, entity_type;

    COMMENT ON TABLE pending_updates IS 'Tracks in-flight transactions for visibility gap management when Redis is unavailable';
    COMMENT ON COLUMN pending_updates.transaction_id IS 'Unique identifier for the transaction';
    COMMENT ON COLUMN pending_updates.entity_type IS 'Type of entity being modified (e.g., user, order, etc.)';
    COMMENT ON COLUMN pending_updates.entity_id IS 'ID of the entity being modified';
    COMMENT ON COLUMN pending_updates.operation IS 'Type of operation: CREATE, UPDATE, or DELETE';
    COMMENT ON COLUMN pending_updates.payload IS 'JSON payload of the transaction';
    COMMENT ON COLUMN pending_updates.kafka_topic IS 'Kafka topic where the message was published';
    COMMENT ON COLUMN pending_updates.kafka_offset IS 'Kafka offset for tracking message position';
  SQL
}

# Store the SQL script in S3 for initialization
resource "aws_s3_object" "pending_updates_table_sql" {
  bucket  = var.s3_bucket_name
  key     = "init/pending_updates_table.sql"
  content = local.pending_updates_table_sql

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-pending-updates-table-sql"
      Description = "SQL script for creating pending updates table"
    }
  )
}