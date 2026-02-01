resource "local_sensitive_file" "options_json" {
  filename = "${path.module}/options.json"
  content = templatefile("${path.module}/options.json.tmpl", {
    bucket            = var.s3_bucket
    region            = var.aws_region
    access_key_id     = aws_iam_access_key.foundry_botuser_access_key.id
    secret_access_key = aws_iam_access_key.foundry_botuser_access_key.secret
  })
}

resource "aws_s3_object" "options_json" {
  bucket  = var.s3_bucket
  key     = join("/", [var.s3_instance_config, "options.json"])
  content = local_sensitive_file.options_json.content
  acl     = "private"
}
