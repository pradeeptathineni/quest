data "aws_caller_identity" "current" {}

resource "circleci_environment_variable" "image_name" {
  project = var.service
  name    = "IMAGE_NAME"
  value   = "quest-app"
}

resource "circleci_environment_variable" "aws_region" {
  project = var.service
  name    = "AWS_ACCOUNT_ID"
  value   = data.aws_caller_identity.current.account_id
}

resource "circleci_environment_variable" "aws_region" {
  project = var.service
  name    = "AWS_REGION"
  value   = var.region
}

resource "circleci_environment_variable" "aws_access_key_id" {
  project = var.service
  name    = "AWS_ACCESS_KEY_ID"
  value   = var.aws_access_key_id
}

resource "circleci_environment_variable" "aws_secret_access_key" {
  project = var.service
  name    = "AWS_SECRET_ACCESS_KEY"
  value   = var.aws_secret_access_key
}

resource "circleci_environment_variable" "ecr_repository_url" {
  project = var.service
  name    = "AWS_ECR_REPO"
  value   = var.ecr_repository_url
}

output "ecr_repo_url" {
  value = var.ecr_repository_url
}
