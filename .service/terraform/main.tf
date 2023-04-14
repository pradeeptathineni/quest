data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

module "network" {
  source      = "./modules/network"
  service     = var.service
  profile     = var.profile
  region      = var.region
  environment = var.environment
}

module "ecr" {
  source      = "./modules/ecr"
  service     = var.service
  profile     = var.profile
  region      = var.region
  environment = var.environment
}

module "alb" {
  source             = "./modules/alb"
  service            = var.service
  profile            = var.profile
  region             = var.region
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  public_subnet_a_id = module.network.public_subnet_a_id
  public_subnet_b_id = module.network.public_subnet_b_id
}

module "ecs" {
  source             = "./modules/ecs"
  service            = var.service
  profile            = var.profile
  region             = var.region
  environment        = var.environment
  image_tag          = var.image_tag
  vpc_id             = module.network.vpc_id
  public_subnet_a_id = module.network.public_subnet_a_id
  public_subnet_b_id = module.network.public_subnet_b_id
  ecr_repo           = module.ecr.ecr_repository_url
  alb_tg_arn         = module.alb.alb_tg_arn
  alb_sg_id          = module.alb.alb_sg_id
}
