variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ca-central-1"
}

variable "environment" {
  description = "Environment name (e.g., production, staging)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "foundryvtt"
}

# ECS Configuration
variable "ecs_cluster_arn" {
  description = "ARN of the existing ECS cluster"
  type        = string
}

variable "foundry_image" {
  description = "Docker image for FoundryVTT"
  type        = string
  default     = "awildphil/foundryvtt:latest"
}

variable "foundry_cpu" {
  description = "CPU units for Fargate task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 1024
}

variable "foundry_memory" {
  description = "Memory for Fargate task in MB (512, 1024, 2048, 4096, 8192, 16384, 30720)"
  type        = number
  default     = 2048
}

variable "foundry_port" {
  description = "Port FoundryVTT listens on"
  type        = number
  default     = 30000
}

variable "desired_count" {
  description = "Desired number of Fargate tasks"
  type        = number
  default     = 1
}

variable "use_spot" {
  description = "Use Fargate Spot pricing (~70% cheaper, but tasks can be interrupted by AWS)"
  type        = bool
  default     = false
}

# Secrets Manager
variable "foundry_secrets_arn" {
  description = "ARN of the Secrets Manager secret containing FoundryVTT credentials"
  type        = string
}

variable "foundry_options_file_arn" {
  description = "ARN of the Secrets Manager secret containing options.json configuration"
  type        = string
}

# EFS Configuration
variable "efs_file_system_id" {
  description = "ID of the existing EFS file system for persistent storage"
  type        = string
}

# Route53 Configuration
variable "domain_name" {
  description = "The main domain name for the Route53 hosted zone"
  type        = string
}

variable "subdomain_name" {
  description = "The subdomain prefix for the Route53 record"
  type        = string
}
