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
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}
