# Reference the network module
# (module) network : Defines the Terraform resources for creating an AWS VPC, two public subnets, and one private subnet to support our service's AWS resources
module "network" {
  source      = "./modules/network"
  service     = var.service
  profile     = var.profile
  region      = var.region
  environment = var.environment
}

# Reference the ecr module
# (module) ecr : Defines the Terraform resources for creating an AWS ECR repository to contain and record the Docker images of our service
module "ecr" {
  source      = "./modules/ecr"
  service     = var.service
  profile     = var.profile
  region      = var.region
  environment = var.environment
}

# Reference the alb module
# (module) alb : Defines the Terraform resources for creating an AWS application loadbalancer to route HTTP and HTTPS traffic to our service
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

# Reference the ecs module
# (module) ecs : Defines the Terraform resources for creating an ECS cluster, task, and service to run our service's Docker image in a serverless container environment
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
