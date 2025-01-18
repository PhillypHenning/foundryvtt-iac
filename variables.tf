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
}

variable "aws_preferred_zone" {
  description = "AWS Zone"
}

variable "instance_type" {
  description = "EC2 Instance Type"
}

variable "key_name" {
  description = "SSH Key Name for access"
}

variable "efs_safehouse" {
  description = "URL of EFS safehouse"
}

variable "subdomain_name" {
  description = "The subdomain prefix for the Route53 record."
}

variable "domain_name" {
  description = "The main domain name for the Route53 hosted zone."
}

variable "default_security_group" {
  description = "The default security group"
}

variable "s3_instance_config_uri" {
  description = "S3 URI to instance config"
}
