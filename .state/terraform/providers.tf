# Define the required provider and backend for the Terraform state
terraform {
  # Specifies the providers used in the configuration
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.17.0"
    }
  }
}

# Configure AWS provider
provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {
      "Owner"       = "Pradeep Tathineni"
      "Company"     = "Rearc"
      "Environment" = var.environment
      "managed_by"  = "terraform"
    }
  }
}

