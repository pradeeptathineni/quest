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
