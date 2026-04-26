resource "aws_s3_bucket_policy" "foundryvtt" {
  bucket = "phil-foundryvtt"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::phil-foundryvtt/*"
    }]
  })
}

resource "aws_s3_bucket_cors_configuration" "foundryvtt" {
  bucket = "phil-foundryvtt"

  cors_rule {
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "HEAD"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}
