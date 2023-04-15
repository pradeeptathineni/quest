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

resource "aws_s3_bucket" "cicd_terraform_state" {
  bucket = "${var.service}-cicd-tfstate-04142023"
  acl    = "private"
}

terraform {
  required_providers {
    circleci = {
      source  = "mrolla/circleci"
      version = "0.4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.17.0"
    }
  }
  backend "s3" {
    bucket = aws_s3_bucket.cicd_terraform_state.bucket
    key    = "terraform.tfstate"
    region = var.region
  }
}

provider "circleci" {
  vcs_type     = "github"
  api_token    = var.circleci_token
  organization = var.github_org
}
