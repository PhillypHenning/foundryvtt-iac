# ECS Task Execution Role (used by ECS to pull images, write logs)
resource "aws_iam_role" "foundry_ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-execution-role"
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "foundry_ecs_task_execution_role_policy" {
  role       = aws_iam_role.foundry_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role (used by the container application itself)
resource "aws_iam_role" "foundry_ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-role"
  }
}

# Policy for Secrets Manager access
resource "aws_iam_role_policy" "foundry_ecs_task_secrets_policy" {
  name = "${var.project_name}-ecs-task-secrets-policy"
  role = aws_iam_role.foundry_ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          data.aws_secretsmanager_secret.foundry_secrets.arn,
          data.aws_secretsmanager_secret.foundry_options_file.arn
        ]
      }
    ]
  })
}

# Policy for EFS access
resource "aws_iam_role_policy" "foundry_ecs_task_efs_policy" {
  name = "${var.project_name}-ecs-task-efs-policy"
  role = aws_iam_role.foundry_ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = "arn:aws:elasticfilesystem:${var.aws_region}:*:file-system/${var.efs_file_system_id}"
      }
    ]
  })
}

# Policy for S3 access (for phil-foundryvtt bucket)
resource "aws_iam_role_policy" "foundry_ecs_task_s3_policy" {
  name = "${var.project_name}-ecs-task-s3-policy"
  role = aws_iam_role.foundry_ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::phil-foundryvtt",
          "arn:aws:s3:::phil-foundryvtt/*"
        ]
      }
    ]
  })
}
