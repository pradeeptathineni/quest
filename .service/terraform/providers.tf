terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.17.0"
    }
  }
  backend "s3" {
    bucket  = "rearc-quest-terraform-state-0423"
    key     = "terraform.tfstate"
    encrypt = true
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
