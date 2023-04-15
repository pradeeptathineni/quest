data "aws_caller_identity" "current" {}

resource "circleci_environment_variable" "image_name" {
  project = var.service
  name    = "IMAGE_NAME"
  value   = var.service
}

resource "circleci_environment_variable" "aws_account_id" {
  project = var.service
  name    = "AWS_ACCOUNT_ID"
  value   = data.aws_caller_identity.current.account_id
}

resource "circleci_environment_variable" "aws_region" {
  project = var.service
  name    = "AWS_REGION"
  value   = var.region
}

resource "circleci_environment_variable" "ecr_repository_url" {
  project = var.service
  name    = "AWS_ECR_REPO_URL"
  value   = var.ecr_repository_url
}

output "ecr_repo_url" {
  value = var.ecr_repository_url
}
