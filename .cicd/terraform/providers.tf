module "state" {
  source = "../../.state/terraform"
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
    key     = "terraform.tfstate"
    encrypt = "true"
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

provider "circleci" {
  vcs_type     = "github"
  api_token    = var.circleci_token
  organization = var.github_org
}
