# Output ECR repository URL
output "ecr_repository_url" {
  value = aws_ecr_repository.ecr_repo.repository_url
}

# Output name of Docker image
output "image_name" {
  value = var.service
}
