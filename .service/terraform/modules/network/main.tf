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

# Create NACL for our public subnets to lock down traffic to only what is necessary for our service
resource "aws_network_acl" "public_acl" {
  vpc_id = aws_vpc.vpc_quest.id
  # Allow TCP SSH inbound from anywhere if anyone needs to troubleshoot compute instances
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }
  # Allow TCP HTTP inbound from anywhere for the web service
  ingress {
    rule_no    = 101
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  # Allow TCP HTTPS inbound from anywhere for the web service
  ingress {
    rule_no    = 102
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  # Allow web server TCP inbound from anywhere for the web service
  ingress {
    rule_no    = 103
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  # Allow all TCP outbound
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }
  # Allow all UDP outbound
  egress {
    rule_no    = 101
    protocol   = "udp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }
}

# Create WAF regional geo match set to match USA only
resource "aws_wafregional_geo_match_set" "usa_only" {
  name = "USAOnlyGeoMatchSet"
  geo_match_constraint {
    type  = "Country"
    value = "US"
  }
}

# Create WAF regional rule to match USA only
resource "aws_wafregional_rule" "usa_only" {
  name        = "USAOnlyRule"
  metric_name = "USAOnlyRule"
  predicate {
    type    = "GeoMatch"
    data_id = aws_wafregional_geo_match_set.usa_only.id
    negated = false
  }
}

# Create WAF regional web ACL to match USA only
resource "aws_wafregional_web_acl" "public_waf" {
  name        = "USAOnlyWebACL"
  metric_name = "USAOnlyWebACL"
  default_action {
    type = "BLOCK"
  }
  rule {
    priority = 1
    action {
      type = "ALLOW"
    }
    rule_id = aws_wafregional_rule.usa_only.id
  }
}

# # Create WAF regional IP set for USA IP ranges
# resource "aws_wafregional_ipset" "usa_ips" {
#   name        = "usa-ips"
#   ip_set_descriptors = [
#     {
#       type  = "IPV4"
#       value = "3.5.0.0/16"
#     },
#     {
#       type  = "IPV4"
#       value = "13.52.0.0/16"
#     },
#     {
#       type  = "IPV4"
#       value = "18.128.0.0/16"
#     },
#     # Add additional IP ranges as needed
#   ]
# }

# Associate the public subnets with their NACL
resource "aws_network_acl_association" "public_acl_association_subnet_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  network_acl_id = aws_network_acl.public_acl.id
}
resource "aws_network_acl_association" "public_acl_association_subnet_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  network_acl_id = aws_network_acl.public_acl.id
}

resource "aws_wafregional_web_acl_association" "public_waf_association" {
  resource_arn = var.alb_arn
  web_acl_id   = aws_wafregional_web_acl.public_waf.id
}
