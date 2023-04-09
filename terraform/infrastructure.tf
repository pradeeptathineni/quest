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

# Associate my key pair
resource "aws_key_pair" "deployer_key" {
  key_name   = "kp-pradeep-quest"
  public_key = file(var.public_key_file_name)
}

# Create IAM user
resource "aws_iam_user" "user_quest" {
  name = "user-quest-create-resources"
}

# Attach policy to IAM user that grants permissions to create resources
resource "aws_iam_user_policy_attachment" "user_quest_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  user       = aws_iam_user.user_quest.name
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

# Create NAT gateway and an Elastic IP address for it
resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_a.id
  tags = {
    Name = "ngw-subnet-pub-a-${var.service}"
  }
}

# Create route table for the private subnet and add a route to the NAT gateway
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc_quest.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

# Associate the private subnet with its private route table
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

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
