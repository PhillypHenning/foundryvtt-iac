output "instance_id" {
  value = aws_instance.foundryvtt.id
}

output "elastic_ip" {
  value = aws_eip.foundryvtt.public_ip
}

output "foundryvtt_url" {
  value = "http://${var.subdomain_name}.${var.domain_name}"
}

output "ssm_connect_command" {
  value = "aws ssm start-session --target ${aws_instance.foundryvtt.id} --region ${var.aws_region}"
}

output "ec2_security_group_id" {
  value = aws_security_group.foundryvtt.id
}
