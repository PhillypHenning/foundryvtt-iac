# ECS Task Definition for EFS Backup
resource "aws_ecs_task_definition" "foundry_backup_task" {
  family                   = "${var.project_name}-backup-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.foundry_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.foundry_backup_task_role.arn

  volume {
    name = "foundry-efs-storage"

    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"
      authorization_config {
        iam = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "backup"
      image     = "amazon/aws-cli:latest"
      essential = true
      command   = [
        "sh",
        "-c",
        <<-EOT
          echo "Starting FoundryVTT EFS backup at $(date)"
          TIMESTAMP=$(date +%Y%m%d-%H%M%S)
          BACKUP_NAME="foundry-efs-backup-$${TIMESTAMP}.tar.gz"
          echo "Creating compressed archive..."
          tar -czf /tmp/$${BACKUP_NAME} -C /data .
          echo "Uploading to S3..."
          aws s3 cp /tmp/$${BACKUP_NAME} s3://phil-foundryvtt/snapshots/$${BACKUP_NAME}
          echo "Cleaning up backups older than 3 months (90 days)..."
          aws s3 ls s3://phil-foundryvtt/snapshots/ | awk '{print $$4}' | grep "^foundry-efs-backup-" | while read file; do
            FILE_DATE=$${file#foundry-efs-backup-}
            FILE_DATE=$${FILE_DATE%%-*}
            if [ ! -z "$$FILE_DATE" ] && [ $$FILE_DATE -lt $(date -d '90 days ago' +%Y%m%d) ]; then
              echo "Deleting old backup: $$file"
              aws s3 rm s3://phil-foundryvtt/snapshots/$$file
            fi
          done
          echo "Backup completed successfully at $(date)"
        EOT
      ]

      mountPoints = [
        {
          sourceVolume  = "foundry-efs-storage"
          containerPath = "/data"
          readOnly      = true
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.foundry_backup_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backup"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-backup-task"
  }
}

# CloudWatch Log Group for Backup Tasks
resource "aws_cloudwatch_log_group" "foundry_backup_logs" {
  name              = "/ecs/${var.project_name}-backup"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-backup-logs"
  }
}

# IAM Role for Backup Task
resource "aws_iam_role" "foundry_backup_task_role" {
  name = "${var.project_name}-backup-task-role"

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

  tags = {
    Name = "${var.project_name}-backup-task-role"
  }
}

# Policy for Backup Task - S3 Access
resource "aws_iam_role_policy" "foundry_backup_s3_policy" {
  name = "${var.project_name}-backup-s3-policy"
  role = aws_iam_role.foundry_backup_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::phil-foundryvtt",
          "arn:aws:s3:::phil-foundryvtt/snapshots/*"
        ]
      }
    ]
  })
}

# Policy for Backup Task - EFS Access
resource "aws_iam_role_policy" "foundry_backup_efs_policy" {
  name = "${var.project_name}-backup-efs-policy"
  role = aws_iam_role.foundry_backup_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = "arn:aws:elasticfilesystem:${var.aws_region}:*:file-system/${var.efs_file_system_id}"
      }
    ]
  })
}

# EventBridge Rule to trigger backup at 2 AM UTC daily
resource "aws_cloudwatch_event_rule" "foundry_backup_schedule" {
  name                = "${var.project_name}-backup-schedule"
  description         = "Trigger FoundryVTT EFS backup daily at 2 AM UTC"
  schedule_expression = "cron(0 2 * * ? *)"

  tags = {
    Name = "${var.project_name}-backup-schedule"
  }
}

# EventBridge Target - Run ECS Task
resource "aws_cloudwatch_event_target" "foundry_backup_target" {
  rule      = aws_cloudwatch_event_rule.foundry_backup_schedule.name
  target_id = "foundry-backup-ecs-task"
  arn       = data.aws_ecs_cluster.foundry_ecs_cluster.arn
  role_arn  = aws_iam_role.foundry_backup_eventbridge_role.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.foundry_backup_task.arn
    launch_type         = "FARGATE"

    network_configuration {
      subnets          = data.aws_subnets.default.ids
      security_groups  = [aws_security_group.foundry_ecs_task_sg.id]
      assign_public_ip = true
    }
  }
}

# IAM Role for EventBridge to run ECS tasks
resource "aws_iam_role" "foundry_backup_eventbridge_role" {
  name = "${var.project_name}-backup-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-backup-eventbridge-role"
  }
}

# Policy for EventBridge to run ECS tasks
resource "aws_iam_role_policy" "foundry_backup_eventbridge_policy" {
  name = "${var.project_name}-backup-eventbridge-policy"
  role = aws_iam_role.foundry_backup_eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask"
        ]
        Resource = [
          aws_ecs_task_definition.foundry_backup_task.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.foundry_ecs_task_execution_role.arn,
          aws_iam_role.foundry_backup_task_role.arn
        ]
      }
    ]
  })
}
