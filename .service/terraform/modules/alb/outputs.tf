# Output ALB ARN
output "alb_tg_arn" {
  value = aws_lb_target_group.lb_tgt_group_http.arn
}

# Output ALB security group ID
output "alb_sg_id" {
  value = aws_security_group.load_balancer_security_group.id
}

# Output ALB DNS address
output "alb_dns" {
  value = aws_lb.app_lb.dns_name
}
