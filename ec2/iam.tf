data "aws_caller_identity" "current" {}

# EC2 instance role — used by both the host and Docker container via instance metadata
resource "aws_iam_role" "foundryvtt_ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_instance_profile" "foundryvtt" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.foundryvtt_ec2.name
}

resource "aws_iam_role_policy" "ec2_secrets" {
  name = "${var.project_name}-ec2-secrets"
  role = aws_iam_role.foundryvtt_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = [var.foundry_secrets_arn, var.foundry_options_file_arn]
    }]
  })
}

resource "aws_iam_role_policy" "ec2_efs" {
  name = "${var.project_name}-ec2-efs"
  role = aws_iam_role.foundryvtt_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientRootAccess"
      ]
      Resource = "arn:aws:elasticfilesystem:${var.aws_region}:${data.aws_caller_identity.current.account_id}:file-system/${var.efs_file_system_id}"
    }]
  })
}

resource "aws_iam_role_policy" "ec2_s3" {
  name = "${var.project_name}-ec2-s3"
  role = aws_iam_role.foundryvtt_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
      Resource = [
        "arn:aws:s3:::phil-foundryvtt",
        "arn:aws:s3:::phil-foundryvtt/*"
      ]
    }]
  })
}

# SSM Session Manager — lets you shell into the instance without SSH keys or bastion
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.foundryvtt_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EventBridge Scheduler role for EC2 start/stop
resource "aws_iam_role" "scheduler_ec2" {
  name = "${var.project_name}-scheduler-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "scheduler_ec2" {
  name = "${var.project_name}-scheduler-ec2"
  role = aws_iam_role.scheduler_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ec2:StartInstances", "ec2:StopInstances"]
      Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project" = "FoundryVTT"
        }
      }
    }]
  })
}
