#######################
## FOUNDRY S3 ACCESS ##
#######################
resource "aws_iam_role" "instance_role" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Policy to allow S3 access to specific bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::phil-foundryvtt",
          "arn:aws:s3:::phil-foundryvtt/InstanceConfig/01172025/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_access" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.instance_role.name
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.instance_role.name
}
#######################

##############
## BOT USER ##
##############
resource "aws_iam_user" "foundry_botuser" {
  name = "foundry_botuser"
}

resource "aws_iam_policy" "foundry_botuser_s3_policy" {
  name        = "FoundryS3ReadOnly"
  description = "Policy to allow read-only access to specific S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::phil-foundryvtt/GameData/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "foundry_botuser_attach_s3_policy" {
  policy_arn = aws_iam_policy.foundry_botuser_s3_policy.arn
  user       = aws_iam_user.foundry_botuser.name
}

resource "aws_iam_access_key" "foundry_botuser_access_key" {
  user = aws_iam_user.foundry_botuser.name
}
##############
