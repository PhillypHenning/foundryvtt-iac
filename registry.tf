# Create application using aliased 'application' provider
provider "aws" {
  alias = "application"
}

resource "aws_servicecatalogappregistry_application" "foundry_appregistry" {
  provider    = aws.application
  name        = "FoundryAppRegistry"
  description = "Foundry App Registry for Cost analysis"
}
