# MSK Configuration with Cross-Region Mirroring Support
resource "aws_msk_configuration" "main" {
  name              = "${var.project_name}-msk-config"
  kafka_versions    = [var.kafka_version]
  server_properties = <<PROPERTIES
auto.create.topics.enable=true
default.replication.factor=3
min.insync.replicas=2
num.io.threads=8
num.network.threads=5
num.replica.fetchers=2
replica.lag.time.max.ms=30000
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
socket.send.buffer.bytes=102400
unclean.leader.election.enable=false
zookeeper.session.timeout.ms=18000
# Cross-region replication settings
replica.fetch.max.bytes=1048576
replica.socket.timeout.ms=30000
replica.socket.receive.buffer.bytes=65536
# Compression for cross-region efficiency
compression.type=snappy
# Topic configuration for mirroring
log.retention.hours=168
log.segment.bytes=1073741824
PROPERTIES

  description = "MSK configuration for ${var.project_name} with cross-region mirroring support"
}

# CloudWatch Log Group for MSK
resource "aws_cloudwatch_log_group" "msk" {
  name              = "/aws/msk/${var.project_name}"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-msk-logs"
    }
  )
}

# MSK Cluster
resource "aws_msk_cluster" "main" {
  cluster_name           = "${var.project_name}-msk-cluster"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.number_of_broker_nodes

  broker_node_group_info {
    instance_type   = var.instance_type
    client_subnets  = var.private_subnet_ids
    security_groups = [var.security_group_id]

    storage_info {
      ebs_storage_info {
        volume_size = var.ebs_volume_size
      }
    }

    connectivity_info {
      public_access {
        type = "DISABLED"
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.main.arn
    revision = aws_msk_configuration.main.latest_revision
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }

    encryption_at_rest_kms_key_arn = aws_kms_key.msk.arn
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
    }
  }

  client_authentication {
    sasl {
      iam = true
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-msk-cluster"
    }
  )
}

# KMS Key for MSK encryption
resource "aws_kms_key" "msk" {
  description             = "KMS key for MSK cluster encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-msk-kms-key"
    }
  )
}

resource "aws_kms_alias" "msk" {
  name          = "alias/${var.project_name}-msk"
  target_key_id = aws_kms_key.msk.key_id
}