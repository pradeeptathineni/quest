#!/usr/bin/make -f
# The above shebang allows execution of this Makefile

SERVICE := quest
IMAGE_NAME := ${SERVICE}
AWS_ACCOUNT_ID := 310981538866
REGION := us-east-1
ECR_REPO_URL := ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Build the Docker image
build:
	docker build -t $(IMAGE_NAME):latest .

# Scan the Docker image for vulnerabilities
scan: 
	docker scan --accept-license $(IMAGE_NAME) || exit 0

# Run the Docker image locally in detached mode; follow logs
run:
	docker logs --follow `docker run -itd --name $(IMAGE_NAME) -p 3000:3000 $(IMAGE_NAME)`

# Stop running Docker container
stop:
	docker stop $(IMAGE_NAME)

# Deploy ECR repo selectively and log into ECR
ecr-login:
	cd .service/terraform && terraform init -backend-config="region=${REGION}" && terraform apply --target=module.ecr.aws_ecr_repository.ecr_repo --auto-approve
	aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO_URL}

# Build Docker image, log into ECR, tag image, and push image to ECR
push: build ecr-login
	docker tag ${IMAGE_NAME}:latest ${ECR_REPO_URL}/${IMAGE_NAME}:latest
	docker push ${ECR_REPO_URL}/${IMAGE_NAME}:latest

# Log into ECR, tag image, and push image to ECR
push-no-build: ecr-login
	docker tag ${IMAGE_NAME}:latest ${ECR_REPO_URL}/${IMAGE_NAME}:latest
	docker push ${ECR_REPO_URL}/${IMAGE_NAME}:latest

# Initialize Terraform state architecture
init-state:
	cd .state/terraform && terraform init
	cd .state/terraform && terraform apply --auto-approve

# Initialize Terraform service architecture
init-service:
	cd .service/terraform && terraform init -backend-config="region=${REGION}"

# Initialize both Terraform architectures
init: init-state init-service

# Deploy Terraform service architecture without building an image
deploy-no-build: init
	cd .service/terraform && terraform apply --auto-approve

# Deploy Terraform state architecture
deploy-state: init-state
	cd .state/terraform && terraform apply --auto-approve

# Deploy ECR selectively within the Terraform service architecture
deploy-ecr: init-service
	cd .service/terraform && terraform apply --target=module.ecr.aws_ecr_repository.ecr_repo --auto-approve

# Deploy Terraform service architecture
deploy-service: init-service
	cd .service/terraform && terraform apply --auto-approve

# Destroy Terraform state architecture
destroy-state:
	cd .state/terraform && terraform destroy --auto-approve

# Destroy Terraform service architecture
destroy-service:
	cd .service/terraform && terraform destroy --auto-approve

# Destroy both Terraform architectures
destroy: destroy-service destroy-state

# Force redeploy of the service running the task holding the image
force-redeploy:
	aws ecs update-service --cluster $(shell cd .service/terraform && terraform output -raw ecs_cluster_name) --service $(shell cd .service/terraform && terraform output -raw ecs_service_name) --force-new-deployment

# If you want to do the full build locally without CircleCI
local-deploy: deploy-state deploy-ecr push deploy-service

# If you want to do the full build locally without build without CircleCI
local-deploy-no-build: deploy-state deploy-ecr deploy-service

