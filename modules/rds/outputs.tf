output "primary_instance_id" {
  description = "ID of the primary RDS instance"
  value       = aws_db_instance.primary.id
}

output "primary_instance_endpoint" {
  description = "Endpoint of the primary RDS instance"
  value       = aws_db_instance.primary.endpoint
}

output "primary_instance_address" {
  description = "Address of the primary RDS instance"
  value       = aws_db_instance.primary.address
}

output "secondary_instance_id" {
  description = "ID of the secondary RDS instance"
  value       = aws_db_instance.secondary.id
}

output "secondary_instance_endpoint" {
  description = "Endpoint of the secondary RDS instance"
  value       = aws_db_instance.secondary.endpoint
}

output "secondary_instance_address" {
  description = "Address of the secondary RDS instance"
  value       = aws_db_instance.secondary.address
}

output "database_name" {
  description = "Name of the database"
  value       = var.database_name
}

output "database_port" {
  description = "Port of the database"
  value       = aws_db_instance.primary.port
}

output "db_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.db_master.arn
}

output "db_secret_name" {
  description = "Name of the database credentials secret"
  value       = aws_secretsmanager_secret.db_master.name
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "parameter_group_name" {
  description = "Name of the DB parameter group"
  value       = aws_db_parameter_group.postgres.name
}