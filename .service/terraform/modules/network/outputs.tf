# Output VPC ID
output "vpc_id" {
  value = aws_vpc.vpc_quest.id
}

# Output public subnet A ID
output "public_subnet_a_id" {
  value = aws_subnet.public_subnet_a.id
}

# Output public subnet A ID
output "public_subnet_b_id" {
  value = aws_subnet.public_subnet_b.id
}
