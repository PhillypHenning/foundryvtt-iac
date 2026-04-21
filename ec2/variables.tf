variable "aws_region" {
  type    = string
  default = "ca-central-1"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "project_name" {
  type    = string
  default = "foundryvtt"
}

variable "instance_type" {
  type        = string
  default     = "t3.small"
  description = "EC2 instance type. t3.small (x86, ~$14/mo) or t4g.small (ARM, ~$11/mo)"
}

variable "foundry_image" {
  type    = string
  default = "awildphil/foundryvtt:latest"
}

variable "foundry_secrets_arn" {
  type = string
}

variable "foundry_options_file_arn" {
  type = string
}

variable "efs_file_system_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "subdomain_name" {
  type    = string
  default = "test"
}

variable "key_pair_name" {
  type        = string
  default     = null
  description = "Optional EC2 key pair name for SSH access. Leave null to use SSM Session Manager instead."
}

variable "schedule_start" {
  type        = string
  default     = "cron(0 22 * * ? *)"
  description = "When to start the instance (UTC). Default: 10 PM UTC = 6 PM EDT / 3 PM PDT"
}

variable "schedule_stop" {
  type        = string
  default     = "cron(0 7 * * ? *)"
  description = "When to stop the instance (UTC). Default: 7 AM UTC = 3 AM EDT / midnight PDT"
}
