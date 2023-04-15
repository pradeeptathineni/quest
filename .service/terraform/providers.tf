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

resource "aws_s3_bucket" "service_terraform_state" {
  bucket = "${var.service}-service-tfstate-04142023"
  acl    = "private"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.17.0"
    }
  }
  backend "s3" {
    bucket = aws_s3_bucket.service_terraform_state.bucket
    key    = "terraform.tfstate"
    region = var.region
  }
}
