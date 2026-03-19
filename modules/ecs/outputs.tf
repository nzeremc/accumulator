output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.app.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.app.family
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "db_init_task_definition_arn" {
  description = "ARN of the DB initialization task definition"
  value       = aws_ecs_task_definition.db_init.arn
}

output "db_init_task_definition_family" {
  description = "Family of the DB initialization task definition"
  value       = aws_ecs_task_definition.db_init.family
}

output "pgactive_task_definition_arn" {
  description = "ARN of the PGActive task definition"
  value       = aws_ecs_task_definition.pgactive.arn
}

output "pgactive_task_definition_family" {
  description = "Family of the PGActive task definition"
  value       = aws_ecs_task_definition.pgactive.family
}

output "db_init_log_group_name" {
  description = "Name of the DB init CloudWatch log group"
  value       = aws_cloudwatch_log_group.db_init.name
}

output "pgactive_log_group_name" {
  description = "Name of the PGActive CloudWatch log group"
  value       = aws_cloudwatch_log_group.pgactive.name
}