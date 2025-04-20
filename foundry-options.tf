# Local variable with JSON-formatted bucket name list
locals {
  s3_parts    = split("/", replace(var.s3_instance_config_uri, "s3://", ""))
  bucket_name = local.s3_parts[0]
  bucket_path = join("/", slice(local.s3_parts, 1, length(local.s3_parts)))
}

resource "local_sensitive_file" "options_json" {
  filename = "${path.module}/options.json"
  content = templatefile("${path.module}/options.json.tmpl", {
    bucket            = local.bucket_name
    region            = var.aws_region
    access_key_id     = aws_iam_access_key.foundry_botuser_access_key.id
    secret_access_key = aws_iam_access_key.foundry_botuser_access_key.secret
  })
}

resource "aws_s3_object" "options_json" {
  bucket  = local.bucket_name
  key     = join("/", [local.bucket_path, "options.json"])
  content = local_sensitive_file.options_json.content
  acl     = "private"
}
