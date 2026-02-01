terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "ph-terraform-state-bucket"
    key    = "foundryvtt-ecs/terraform.tfstate"
    region = "ca-central-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "FoundryVTT"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Implementation = "ECS"
    }
  }
}
