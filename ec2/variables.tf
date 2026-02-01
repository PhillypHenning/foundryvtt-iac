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

variable "s3_instance_config" {
  description = "Path to instance config within S3"
}

variable "worlds_data_dir" {
  type = string
}

variable "s3_snapshot_directory" {
  type    = string
  default = "snapshots"
}

variable "s3_bucket" {
  type = string
}

variable "ssh_private_key_path" {
  type        = string
  description = "Absolute path to the EC2 private key PEM file"
}
