# Define the required provider and backend for the Terraform state
terraform {
  # Specifies the providers used in the configuration
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.17.0"
    }
  }
  # Specifies the backend where the Terraform state is stored
  # Every time this Terraform project is initialized, it will connect to this S3 bucket to pull the terraform.tfstate file
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
