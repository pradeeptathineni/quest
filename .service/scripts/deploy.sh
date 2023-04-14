#!/bin/sh

IMAGE_NAME="quest-app"
AWS_ACCOUNT_ID=310981538866
REGION="us-east-1"
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

if [ "$1" == "--deploy" ]; then
    cd ../..
    docker build -t $(IMAGE_NAME):latest .
    cd terraform
    terraform init
    terraform apply --target=aws_ecr_repository.ecr_repo --auto-approve
    aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
    docker tag ${IMAGE_NAME}:latest ${ECR_REPO}/${IMAGE_NAME}:latest
    docker push ${ECR_REPO}/${IMAGE_NAME}:latest
    terraform apply --auto-approve
elif [ "$1" == "--redeploy" ]; then
    cd ../terraform
    terraform apply --auto-approve
else
    echo "Usage: ./deploy.sh [--deploy|--redeploy]"
fi



