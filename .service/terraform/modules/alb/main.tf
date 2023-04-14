# Create the security group for the load balancer level
resource "aws_security_group" "load_balancer_security_group" {
  description = "Security group for load balancer"
  vpc_id      = var.vpc_id
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

# Create application loadbalancer
resource "aws_lb" "app_lb" {
  name               = "lb-${var.service}"
  load_balancer_type = "application"
  subnets = [
    var.public_subnet_a_id,
    var.public_subnet_b_id
  ]
  security_groups = [aws_security_group.load_balancer_security_group.id]
}

# Create HTTP loadbalancer target group
resource "aws_lb_target_group" "lb_tgt_group_http" {
  name        = "target-group-http-${var.service}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
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
