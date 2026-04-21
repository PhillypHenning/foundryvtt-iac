# Start instance each evening
resource "aws_scheduler_schedule" "start" {
  name       = "${var.project_name}-start"
  group_name = "default"

  flexible_time_window { mode = "OFF" }
  schedule_expression          = var.schedule_start
  schedule_expression_timezone = "UTC"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.scheduler_ec2.arn
    input = jsonencode({ InstanceIds = [aws_instance.foundryvtt.id] })
  }
}

# Stop instance each morning
resource "aws_scheduler_schedule" "stop" {
  name       = "${var.project_name}-stop"
  group_name = "default"

  flexible_time_window { mode = "OFF" }
  schedule_expression          = var.schedule_stop
  schedule_expression_timezone = "UTC"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler_ec2.arn
    input = jsonencode({ InstanceIds = [aws_instance.foundryvtt.id] })
  }
}
