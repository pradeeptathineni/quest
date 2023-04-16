# Output ALB DNS address
output "alb_dns" {
  value = module.alb.alb_dns
}

# Output ECR repository URL
output "ecr_repository_url" {
  value = module.ecr.ecr_repository_url
}

# Output image name saved in this ecr repo
output "image_name" {
  value = module.ecr.image_name
}

# Output ECS cluster name
output "ecs_cluster_name" {
  value = module.ecs.ecs_cluster_name
}

# Output ECS service name
output "ecs_service_name" {
  value = module.ecs.ecs_service_name
}
