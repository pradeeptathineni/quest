# Create ECR repository
resource "aws_ecr_repository" "ecr_repo" {
  name                 = "${var.service}-app"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Create ECR lifecycle policy
resource "aws_ecr_lifecycle_policy" "ecr_repo_policy" {
  repository = aws_ecr_repository.ecr_repo.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep latest image"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
