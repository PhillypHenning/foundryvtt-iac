output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = data.aws_ecs_cluster.foundry_ecs_cluster.cluster_name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.foundry_ecs_task.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for ECS tasks"
  value       = aws_cloudwatch_log_group.foundry_ecs_logs.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.foundry_ecs_service.name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = data.aws_subnets.default.ids
}

output "security_group_id" {
  description = "ID of the ECS task security group"
  value       = aws_security_group.foundry_ecs_task_sg.id
}

output "options_secret_arn" {
  description = "ARN of the options.json secret"
  value       = data.aws_secretsmanager_secret.foundry_options_file.arn
}
