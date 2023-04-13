terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    circleci = {
      source  = "mrolla/circleci"
      version = "0.6.1"
    }
  }
}

# Configure AWS provider
provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {
      "Owner"       = "Pradeep Tathineni"
      "Company"     = "Rearc"
      "Environment" = var.environment
      "managed_by"  = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# Create VPC
resource "aws_vpc" "vpc_quest" {
  cidr_block = "10.7.0.0/16"
  tags = {
    Name = "vpc-${var.service}"
  }
}

# Create public subnet A
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.vpc_quest.id
  cidr_block              = "10.7.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-${var.region}a-pub-${var.service}"
  }
}

# Create public subnet B
resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.vpc_quest.id
  cidr_block        = "10.7.2.0/24"
  availability_zone = "${var.region}b"
  tags = {
    Name = "subnet-${var.region}b-pub-${var.service}"
  }
}

# Create private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc_quest.id
  cidr_block        = "10.7.0.0/24"
  availability_zone = "${var.region}c"
  tags = {
    Name = "subnet-${var.region}c-prv-${var.service}"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_quest.id
  tags = {
    Name = "igw-${var.service}"
  }
}

# Create route table for the public subnets
resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = aws_vpc.vpc_quest.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "rt-subnet-pub-${var.service}"
  }
}

# Associate the public subnets with their route table
resource "aws_route_table_association" "public_subnet_a_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_subnet_route_table.id
}
resource "aws_route_table_association" "public_subnet_b_association" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_subnet_route_table.id
}

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
      image = "${aws_ecr_repository.ecr_repo.repository_url}:latest"
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

# Create the security group for the load balancer level
resource "aws_security_group" "load_balancer_security_group" {
  description = "Security group for load balancer"
  vpc_id      = aws_vpc.vpc_quest.id
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Create the security group for the container level
resource "aws_security_group" "service_security_group" {
  description = "Security group for containers"
  vpc_id      = aws_vpc.vpc_quest.id
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    // Only allowing traffic in from the load balancer security group
    security_groups = [aws_security_group.load_balancer_security_group.id]
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
    subnets          = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
    security_groups  = [aws_security_group.service_security_group.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.lb_tgt_group_http.arn
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
          Service = "ecs-tasks.amazonaws.com"
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

# Create application loadbalancer
resource "aws_lb" "app_lb" {
  name               = "lb-${var.service}"
  load_balancer_type = "application"
  subnets = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_b.id
  ]
  security_groups = [aws_security_group.load_balancer_security_group.id]
}

# Create HTTP loadbalancer target group
resource "aws_lb_target_group" "lb_tgt_group_http" {
  name        = "target-group-http-${var.service}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_quest.id
  target_type = "ip"
  health_check {
    healthy_threshold   = "3"
    interval            = "60"
    protocol            = "HTTP"
    matcher             = "200-299,301,302"
    timeout             = "50"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

# Create HTTP loadbalancer listener
resource "aws_lb_listener" "listener_http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Create TLS private key
resource "tls_private_key" "tls_pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create TLS self signed certificate
resource "tls_self_signed_cert" "tls_ssc" {
  private_key_pem = tls_private_key.tls_pk.private_key_pem
  subject {
    common_name  = "${var.region}.elb.amazonaws.com"
    organization = "Rearc"
  }
  validity_period_hours = 720
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}

# Create ACM certificate
resource "aws_acm_certificate" "tls_cert" {
  private_key      = tls_private_key.tls_pk.private_key_pem
  certificate_body = tls_self_signed_cert.tls_ssc.cert_pem
}

# Create HTTPS loadbalancer listener
resource "aws_lb_listener" "listener_https" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.tls_cert.arn
  default_action {
    target_group_arn = aws_lb_target_group.lb_tgt_group_http.arn
    type             = "forward"
  }
}

# Output ALB DNS address
output "alb_dns" {
  value = aws_lb.app_lb.dns_name
}

provider "circleci" {
  api_token = var.CIRCLECI_TOKEN
}

resource "aws_iam_role" "circleci_ecr_upload_role" {
  name = "circleci_ecr_upload_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecr.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "servicecatalog.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "CircleCI ECR Upload Role"
  }
}

resource "aws_iam_policy" "circleci_ecr_upload_policy" {
  name_prefix = "circleci_ecr_upload_policy_"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "circleci_ecr_upload_policy_attachment" {
  policy_arn = aws_iam_policy.circleci_ecr_upload_policy.arn
  role       = aws_iam_role.circleci_ecr_upload_role.name
}


data "template_file" "circleci_config" {
  template = file("../../.circleci/config.yml")
  vars = {
    aws_region         = var.region
    aws_account_id     = local.account_id
    aws_ecr_repository = aws_ecr_repository.ecr_repo.name
    aws_iam_role       = aws_iam_role.circleci_ecr_upload_role.name
  }
}

resource "circleci_project" "example" {
  name      = "example"
  vcs_type  = "github"
  username  = "pradeeptathineni"
  repo_name = "quest"
  config    = data.template_file.circleci_config.rendered
}
