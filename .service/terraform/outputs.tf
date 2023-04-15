# Output ALB DNS address
output "alb_dns" {
  value = module.alb.alb_dns
}

# Output ECS cluster name
output "ecs_cluster_name" {
  value = module.ecs.ecs_cluster_name
}

# Output ECS service name
output "ecs_service_name" {
  value = module.ecs.ecs_service_name
}
