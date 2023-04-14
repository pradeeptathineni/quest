terraform {
  required_providers {
    circleci = {
      source  = "mrolla/circleci"
      version = "0.4.0"
    }
  }
}
provider "circleci" {
  vcs_type     = "github"
  api_token    = var.circleci_token
  organization = var.github_org
}
