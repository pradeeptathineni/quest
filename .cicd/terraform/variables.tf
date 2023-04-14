variable "service" {
  description = "Name of the service we are bringing up"
  type        = string
  default     = "quest"
}

variable "profile" {
  description = "The local AWS user profile with access to the service account"
  type        = string
  default     = "default"
}

variable "region" {
  description = "AWS region for deploying resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "github_circleci_pat" {
  type = string
}

variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}
