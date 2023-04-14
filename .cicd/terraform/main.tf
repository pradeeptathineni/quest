resource "circleci_project_environment_variable" "aws_access_key_id" {
  project_slug = var.service
  name         = "AWS_ACCESS_KEY_ID"
  value        = var.aws_access_key_id
}

resource "circleci_project_environment_variable" "aws_secret_access_key" {
  project_slug = var.service
  name         = "AWS_SECRET_ACCESS_KEY"
  value        = var.aws_secret_access_key
}

resource "circleci_project_environment_variable" "aws_ecr_repo" {
  project_slug = var.service
  name         = "AWS_ECR_REPO"
  value        = var.aws_secret_access_key
}
