output "instance_public_ip" {
  value = aws_instance.foundry_instance.public_ip
}

output "user_access_key" {
  description = "Access key for the IAM user"
  value       = aws_iam_access_key.foundry_botuser_access_key.id
}

output "user_secret_key" {
  description = "Secret key for the IAM user"
  value       = aws_iam_access_key.foundry_botuser_access_key.secret
  sensitive   = true
}
