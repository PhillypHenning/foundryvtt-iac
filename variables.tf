variable "allowed_ips" {
  description = "List of IPs allowed to access the instance"
  type        = list(string)
}

variable "admin_ips" {
  description = "List of IPs allowed to access and SSH into the instance"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  default     = "t2.micro"  # Free-tier eligible instance
}

variable "key_name" {
  description = "SSH Key Name for access"
}