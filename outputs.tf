output "instance_public_ip" {
  value = aws_instance.foundry_instance.public_ip
}