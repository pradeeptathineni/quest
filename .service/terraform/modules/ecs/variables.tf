# Request these variables to exist, so they can be ported from root main.tf
variable "service" {}
variable "profile" {}
variable "region" {}
variable "environment" {}
variable "image_tag" {}
variable "vpc_id" {}
variable "public_subnet_a_id" {}
variable "public_subnet_b_id" {}
variable "ecr_repo" {}
variable "alb_tg_arn" {}
variable "alb_sg_id" {}
