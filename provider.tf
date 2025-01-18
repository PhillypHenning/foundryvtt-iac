provider "aws" {
  region = "ca-central-1" 
}

terraform {
  backend "s3" {
    bucket         = "ph-terraform-state-bucket"
    key            = "foundryvtt-iac/terraform.tfstate"
    region         = "ca-central-1"
    encrypt        = true
  }
}
