#!/usr/bin/make -f
# The above shebang allows execution of this Makefile

IMAGE_NAME := pradeep-quest
AWS_ACCOUNT_ID := 310981538866

build:
	@echo "---> Building Docker image '$(IMAGE_NAME)' <---"
	docker build -t $(IMAGE_NAME) .

inspect:
	@echo "---> Inspecting Docker image '$(IMAGE_NAME)' <---"
	docker image inspect $(IMAGE_NAME)

run: 
	docker logs --follow `docker run -itd --name $(IMAGE_NAME) -p 3000:3000 $(IMAGE_NAME)`

stop:
	docker stop $(IMAGE_NAME)

scan: 
	docker scan --accept-license $(IMAGE_NAME) || exit 0