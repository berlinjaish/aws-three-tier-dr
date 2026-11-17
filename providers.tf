
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}



# Primary region: Mumbai
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

# Disaster Recovery region: Hyderabad
provider "aws" {
  alias  = "dr"
  region = var.dr_region
}
