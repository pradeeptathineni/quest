# Create ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster-${var.service}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Create CloudWatch log group for container logs
resource "aws_cloudwatch_log_group" "logs" {
  name              = "logs-${var.service}"
  retention_in_days = 7
}

# Create ECS task definition to define the container
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = var.service
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  memory                   = 512
  cpu                      = 256
  container_definitions = jsonencode([
    {
      name  = "${var.service}-container"
      image = "${var.ecr_repo}:${var.image_tag}"
      portMappings = [{
        containerPort = 3000
        hostPort      = 3000
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.logs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# Create the security group for the container level
resource "aws_security_group" "service_security_group" {
  description = "Security group for containers"
  vpc_id      = var.vpc_id
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    // Only allowing traffic in from the load balancer security group
    security_groups = [var.alb_sg_id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Create ECS service to bring up two duplicate containers
resource "aws_ecs_service" "ecs_service" {
  name            = "${var.service}-service"
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.ecs_cluster.name
  network_configuration {
    subnets          = [var.public_subnet_a_id, var.public_subnet_b_id]
    security_groups  = [aws_security_group.service_security_group.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = var.alb_arn
    container_name   = "${var.service}-container"
    container_port   = 3000
  }
}

# Create IAM role for ECS task execution
resource "aws_iam_role" "task_execution_role" {
  name = "${var.service}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name = "${var.service}-task-role"
  }
}

# Create IAM role policy attachment to attach ECS task execution policy to role
resource "aws_iam_role_policy_attachment" "my_app_task_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.task_execution_role.name
}
