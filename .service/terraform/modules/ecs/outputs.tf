# Output ECS cluster name
output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}

# Output ECS service name
output "ecs_service_name" {
  value = aws_ecs_service.ecs_service.name
}
