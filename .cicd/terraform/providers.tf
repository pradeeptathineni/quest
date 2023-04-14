terraform {
  required_providers {
    circleci = {
      source  = "mrolla/circleci"
      version = ">=0.6.1"
    }
  }
}
provider "circleci" {
  vcs_type     = "github"
  api_token    = var.github_circleci_pat
  organization = var.github_org
}
