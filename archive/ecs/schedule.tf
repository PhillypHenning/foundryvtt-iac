# Scheduled start/stop to reduce ECS Fargate costs.
# Server runs 3pm–midnight MT daily (9 hrs/day vs 24/7).
# UTC times account for MST (UTC-7): 3pm MST = 22:00 UTC, midnight MST = 07:00 UTC.
# Note: shifts by 1 hour during MDT (summer): starts 4pm MDT, stops 1am MDT.

# Register the ECS service as a scalable target
resource "aws_appautoscaling_target" "foundry_ecs_target" {
  max_capacity       = 1
  min_capacity       = 0
  resource_id        = "service/${split("/", var.ecs_cluster_arn)[1]}/${aws_ecs_service.foundry_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Start the server daily at 3pm MST / 4pm MDT (22:00 UTC)
resource "aws_appautoscaling_scheduled_action" "foundry_scale_up" {
  name               = "${var.project_name}-scale-up"
  service_namespace  = aws_appautoscaling_target.foundry_ecs_target.service_namespace
  resource_id        = aws_appautoscaling_target.foundry_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.foundry_ecs_target.scalable_dimension
  schedule           = "cron(0 22 * * ? *)"

  scalable_target_action {
    min_capacity = 1
    max_capacity = 1
  }
}

# Stop the server daily at midnight MST / 1am MDT (07:00 UTC)
resource "aws_appautoscaling_scheduled_action" "foundry_scale_down" {
  name               = "${var.project_name}-scale-down"
  service_namespace  = aws_appautoscaling_target.foundry_ecs_target.service_namespace
  resource_id        = aws_appautoscaling_target.foundry_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.foundry_ecs_target.scalable_dimension
  schedule           = "cron(0 7 * * ? *)"

  scalable_target_action {
    min_capacity = 0
    max_capacity = 0
  }
}
