terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

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

# # Associate my key pair
# resource "aws_key_pair" "deployer_key" {
#   key_name   = "kp-pradeep-quest"
#   public_key = file(var.public_key_file_name)
# }

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

# # Create NAT gateway and an Elastic IP address for it
# resource "aws_eip" "nat_eip" {
#   vpc = true
# }

# resource "aws_nat_gateway" "nat_gateway" {
#   allocation_id = aws_eip.nat_eip.id
#   subnet_id     = aws_subnet.public_subnet_a.id
#   tags = {
#     Name = "ngw-subnet-pub-a-${var.service}"
#   }
# }

# # Create route table for the private subnet and add a route to the NAT gateway
# resource "aws_route_table" "private_route_table" {
#   vpc_id = aws_vpc.vpc_quest.id
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat_gateway.id
#   }
# }

# # Associate the private subnet with its private route table
# resource "aws_route_table_association" "private_subnet_association" {
#   subnet_id      = aws_subnet.private_subnet.id
#   route_table_id = aws_route_table.private_route_table.id
# }

# # Create a security group for public subnet A to allow ingress from anywhere
# resource "aws_security_group" "sg_1" {
#   description = "Allow TCP and ICMP from everywhere"
#   vpc_id      = aws_vpc.vpc_quest.id
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = -1
#     to_port     = -1
#     protocol    = "icmp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name = "sg-all-ingress-to-pubA-${var.service}"
#   }
# }

# # Create a security group for private subnet to allow ingress from public subnet A
# resource "aws_security_group" "sg_2" {
#   description = "Allow TCP and ICMP from public subnet A"
#   vpc_id      = aws_vpc.vpc_quest.id
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["10.7.1.0/24"]
#   }
#   ingress {
#     from_port   = -1
#     to_port     = -1
#     protocol    = "icmp"
#     cidr_blocks = ["10.7.1.0/24"]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name = "sg-pubA-ingress-to-prv-${var.service}"
#   }
# }

# # Launch an EC2 instance in public subnet A
# resource "aws_instance" "instance_public_a" {
#   ami                    = "ami-0fc61db8544a617ed"
#   instance_type          = "t2.micro"
#   subnet_id              = aws_subnet.public_subnet_a.id
#   vpc_security_group_ids = [aws_security_group.sg_1.id]
#   key_name               = aws_key_pair.deployer_key.key_name
#   tags = {
#     Name = "ec2-subnet-us-east-1a-pub-${var.service}"
#   }
# }

# # Launch an EC2 instance in the private subnet
# resource "aws_instance" "instance_private" {
#   ami                    = "ami-0fc61db8544a617ed"
#   instance_type          = "t2.micro"
#   subnet_id              = aws_subnet.private_subnet.id
#   vpc_security_group_ids = [aws_security_group.sg_2.id]
#   tags = {
#     Name = "ec2-subnet-us-east-1c-prv-${var.service}"
#   }
# }

# # Output the private EC2 public IP
# output "public_instance_public_ip" {
#   value = aws_instance.instance_public_a.public_ip
# }

# # Output the private EC2 private IP
# output "private_instance_private_ip" {
#   value = aws_instance.instance_private.private_ip
# }

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
        description  = "Expire images older than 30 days"
        rulePriority = 1
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 30
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
      }]
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
    matcher = "200"
    path    = "/"
  }
}

# Create HTTP loadbalancer listener
resource "aws_lb_listener" "listener_http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.lb_tgt_group_http.arn
    type             = "forward"
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

# Create HTTPS loadbalancer target group
resource "aws_lb_target_group" "lb_tgt_group_https" {
  name        = "target-group-https-${var.service}"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.vpc_quest.id
  target_type = "ip"
  health_check {
    matcher = "200"
    path    = "/"
  }
}

# Create HTTPS loadbalancer listener
resource "aws_lb_listener" "listener_https" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.tls_cert.arn
  default_action {
    target_group_arn = aws_lb_target_group.lb_tgt_group_https.arn
    type             = "forward"
  }
}

# Output ALB DNS address
output "alb_dns" {
  value = aws_lb.app_lb.dns_name
}
