data "aws_secretsmanager_secret" "foundry_secrets" {
  arn = var.foundry_secrets_arn
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.foundry_secrets.id
}

data "aws_secretsmanager_secret" "foundry_options_file" {
  arn = var.foundry_options_file_arn
}