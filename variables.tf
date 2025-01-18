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
  default     = "ca-central-1"
}

variable "aws_preferred_zone" {
  description = "AWS Zone"
  default     = "ca-central-1a"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  default     = "t2.micro" # Free-tier eligible instance
}

variable "key_name" {
  description = "SSH Key Name for access"
}

variable "efs_safehouse" {
  description = "URL of EFS safehouse"
}

variable "subdomain_name" {
  description = "The subdomain prefix for the Route53 record."
  default     = "foundryvtt"
}

variable "domain_name" {
  description = "The main domain name for the Route53 hosted zone."
  default     = "edge-of-the-universe.ca"
}
