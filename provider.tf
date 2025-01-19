provider "aws" {
  region = "ca-central-1"
  default_tags {
    tags = aws_servicecatalogappregistry_application.foundry_appregistry.application_tag
  }
}

terraform {
  backend "s3" {
    bucket  = "ph-terraform-state-bucket"
    key     = "foundryvtt-iac/terraform.tfstate"
    region  = "ca-central-1"
    encrypt = true
  }
}
