#!/usr/bin/make -f
# The above shebang allows execution of this Makefile

IMAGE_NAME := quest-app
AWS_ACCOUNT_ID := 310981538866
REGION := us-east-1
ECR_REPO := ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

build:
	@echo "---> Building Docker image '$(IMAGE_NAME)' <---"
	docker build -t $(IMAGE_NAME):latest .

inspect:
	@echo "---> Inspecting Docker image '$(IMAGE_NAME)' <---"
	docker image inspect $(IMAGE_NAME)

scan: 
	@echo "---> Scanning Docker image '$(IMAGE_NAME)' <---"
	docker scan --accept-license $(IMAGE_NAME) || exit 0

run:
	docker logs --follow `docker run -itd --name $(IMAGE_NAME) -p 3000:3000 $(IMAGE_NAME)`

stop:
	docker stop $(IMAGE_NAME)

deploy: build
	terraform init
	terraform apply --target=aws_ecr_repository.ecr_repo --auto-approve
	aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
	docker tag ${IMAGE_NAME}:latest ${ECR_REPO}/${IMAGE_NAME}:latest
	docker push ${ECR_REPO}/${IMAGE_NAME}:latest
	terraform apply --auto-approve

redeploy:
	terraform apply --auto-approve