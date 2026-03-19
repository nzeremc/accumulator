output "app_repository_url" {
  description = "URL of the application ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "app_repository_arn" {
  description = "ARN of the application ECR repository"
  value       = aws_ecr_repository.app.arn
}

output "app_repository_name" {
  description = "Name of the application ECR repository"
  value       = aws_ecr_repository.app.name
}

output "db_init_repository_url" {
  description = "URL of the DB init ECR repository"
  value       = aws_ecr_repository.db_init.repository_url
}

output "db_init_repository_arn" {
  description = "ARN of the DB init ECR repository"
  value       = aws_ecr_repository.db_init.arn
}

output "db_init_repository_name" {
  description = "Name of the DB init ECR repository"
  value       = aws_ecr_repository.db_init.name
}

output "pgactive_repository_url" {
  description = "URL of the PGActive ECR repository"
  value       = aws_ecr_repository.pgactive.repository_url
}

output "pgactive_repository_arn" {
  description = "ARN of the PGActive ECR repository"
  value       = aws_ecr_repository.pgactive.arn
}

output "pgactive_repository_name" {
  description = "Name of the PGActive ECR repository"
  value       = aws_ecr_repository.pgactive.name
}