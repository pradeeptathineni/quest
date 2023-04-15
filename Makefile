#!/usr/bin/make -f
# The above shebang allows execution of this Makefile

SERVICE := quest
IMAGE_NAME := ${SERVICE}-app
AWS_ACCOUNT_ID := 310981538866
REGION := us-east-1
ECR_REPO_URL := ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com
ECR_REPO_NAME := ${SERVICE}-ecr-repo

build:
	docker build -t $(IMAGE_NAME):latest .

inspect:
	docker image inspect $(IMAGE_NAME)

scan: 
	docker scan --accept-license $(IMAGE_NAME) || exit 0

run:
	docker logs --follow `docker run -itd --name $(IMAGE_NAME) -p 3000:3000 $(IMAGE_NAME)`

stop:
	docker stop $(IMAGE_NAME)

push: build
	aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO_URL}
	docker tag ${IMAGE_NAME}:latest ${ECR_REPO_URL}/${IMAGE_NAME}:latest
	docker push ${ECR_REPO_URL}/${IMAGE_NAME}:latest

push-no-build:
	aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO_URL}
	docker tag ${IMAGE_NAME}:latest ${ECR_REPO_URL}/${IMAGE_NAME}:latest
	docker push ${ECR_REPO_URL}/${IMAGE_NAME}:latest

init-state:
	cd .state/terraform && terraform init
	cd .state/terraform && terraform apply --auto-approve

init-service:
	cd .service/terraform && terraform init -backend-config="bucket=$(shell cd .state/terraform && terraform output -raw service_terraform_state_bucket)" -backend-config="region=${REGION}"

init-cicd:
	cd .cicd/terraform && terraform init -backend-config="bucket=$(shell cd .state/terraform && terraform output -raw cicd_terraform_state_bucket)" -backend-config="region=${REGION}"

init: init-state init-service init-cicd


deploy: build
	aws ecr describe-repositories --repository-names ${ECR_REPO_NAME} || $(cd .service/terraform && terraform init && terraform apply --target=module.ecr.aws_ecr_repository.ecr_repo --auto-approve)
	aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO_URL}
	docker tag ${IMAGE_NAME}:latest ${ECR_REPO_URL}/${IMAGE_NAME}:latest
	docker push ${ECR_REPO_URL}/${IMAGE_NAME}:latest
	cd .service/terraform && terraform apply --auto-approve

deploy-no-build: init-service
	cd .service/terraform && terraform apply --auto-approve

deploy-state:
	cd .state/terraform && terraform apply --auto-approve

deploy-ecr: init-service
	cd .service/terraform && terraform init && terraform apply --target=module.ecr.aws_ecr_repository.ecr_repo --auto-approve

deploy-cicd: init-cicd
	cd .cicd/terraform && terraform init && terraform apply --auto-approve

destroy-state:
	cd .state/terraform && terraform destroy --auto-approve

destroy-service:
	cd .service/terraform && terraform destroy --auto-approve

destroy-cicd:
	cd .cicd/terraform && terraform destroy --auto-approve

ci-deploy: deploy-ecr push deploy-cicd

local-deploy: deploy

destroy: destroy-cicd destroy-service destroy-state