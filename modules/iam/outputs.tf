output "ecs_task_execution_role_arn" {
  description = "ARN of ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

output "db_init_task_role_arn" {
  description = "ARN of database initialization task role"
  value       = aws_iam_role.db_init_task.arn
}

output "ecs_task_execution_role_name" {
  description = "Name of ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.name
}

output "ecs_task_role_name" {
  description = "Name of ECS task role"
  value       = aws_iam_role.ecs_task.name
}

output "db_init_task_role_name" {
  description = "Name of database initialization task role"
  value       = aws_iam_role.db_init_task.name
}