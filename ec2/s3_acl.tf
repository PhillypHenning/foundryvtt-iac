resource "aws_s3_bucket_policy" "foundry-botuser-read-access" {
  bucket = "phil-foundryvtt"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowFoundryBotUserAndInstanceRoleRead"
        Effect = "Allow"
        Principal = {
          AWS = ["*"]
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::phil-foundryvtt",
          "arn:aws:s3:::phil-foundryvtt/*"
        ]
      },
      {
        "Sid" : "AllowAssumedEc2RolePush",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "${aws_iam_role.instance_role.arn}"
        },
        "Action" : "s3:PutObject",
        "Resource" : [
          "arn:aws:s3:::phil-foundryvtt",
          "arn:aws:s3:::phil-foundryvtt/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_cors_configuration" "foundry-s3bucket" {
  bucket = "phil-foundryvtt"

  cors_rule {
    allowed_headers = [
      "*",
    ]
    allowed_methods = [
      "GET",
      "HEAD",
      "POST",
    ]
    allowed_origins = [
      "*.edge-of-the-universe.ca",
    ]
    expose_headers  = []
    max_age_seconds = 3000
  }
}
