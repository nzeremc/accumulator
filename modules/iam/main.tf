# Get current AWS partition for GovCloud compatibility
data "aws_partition" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# ECS Service-Linked Role
# Reference the existing service-linked role (created automatically by AWS)
# If it doesn't exist, AWS will create it automatically when ECS service is created
data "aws_iam_role" "ecs_service_linked" {
  name = "AWSServiceRoleForECS"
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name_prefix = "${var.project_name}-ecs-task-execution-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ecs-task-execution-role"
    }
  )
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for ECS task execution to access S3
resource "aws_iam_role_policy" "ecs_task_execution_s3" {
  name_prefix = "${var.project_name}-ecs-task-execution-s3-"
  role        = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# ECS Task Role (for application runtime)
resource "aws_iam_role" "ecs_task" {
  name_prefix = "${var.project_name}-ecs-task-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ecs-task-role"
    }
  )
}

# Policy for ECS tasks to access S3
resource "aws_iam_role_policy" "ecs_task_s3" {
  name_prefix = "${var.project_name}-ecs-task-s3-"
  role        = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Policy for ECS tasks to access Secrets Manager (for DB credentials)
resource "aws_iam_role_policy" "ecs_task_secrets" {
  name_prefix = "${var.project_name}-ecs-task-secrets-"
  role        = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.db_secret_arn
      }
    ]
  })
}

# Policy for ECS tasks to write logs
resource "aws_iam_role_policy" "ecs_task_logs" {
  name_prefix = "${var.project_name}-ecs-task-logs-"
  role        = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# Policy for ECS tasks to access MSK (Kafka)
resource "aws_iam_role_policy" "ecs_task_msk" {
  name_prefix = "${var.project_name}-ecs-task-msk-"
  role        = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:AlterCluster",
          "kafka-cluster:DescribeCluster"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:kafka:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:*Topic*",
          "kafka-cluster:WriteData",
          "kafka-cluster:ReadData"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:kafka:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:kafka:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:group/*"
        ]
      }
    ]
  })
}

# Policy for ECS tasks to access ElastiCache (Redis)
resource "aws_iam_role_policy" "ecs_task_redis" {
  name_prefix = "${var.project_name}-ecs-task-redis-"
  role        = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeReplicationGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# DB Initialization Task Role
resource "aws_iam_role" "db_init_task" {
  name_prefix = "${var.project_name}-db-init-task-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-init-task-role"
    }
  )
}

# Policy for DB initialization task to access S3
resource "aws_iam_role_policy" "db_init_task_s3" {
  name_prefix = "${var.project_name}-db-init-task-s3-"
  role        = aws_iam_role.db_init_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Policy for DB initialization task to access Secrets Manager
resource "aws_iam_role_policy" "db_init_task_secrets" {
  name_prefix = "${var.project_name}-db-init-task-secrets-"
  role        = aws_iam_role.db_init_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.db_secret_arn
      }
    ]
  })
}

# Policy for DB initialization task to write logs
resource "aws_iam_role_policy" "db_init_task_logs" {
  name_prefix = "${var.project_name}-db-init-task-logs-"
  role        = aws_iam_role.db_init_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}