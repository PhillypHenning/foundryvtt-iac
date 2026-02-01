.PHONY: help build push all login

# Docker image settings
IMAGE_NAME := awildphil/foundryvtt
DOCKERFILE_DIR := ecs/docker

# Extract base image tag from Dockerfile (macOS compatible)
BASE_TAG := $(shell sed -n 's/FROM felddy\/foundryvtt:\([^ ]*\).*/\1/p' $(DOCKERFILE_DIR)/Dockerfile)

help:
	@echo "FoundryVTT Docker Image Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  build      - Build the Docker image"
	@echo "  push       - Push the image to Docker Hub"
	@echo "  all        - Build and push the image"
	@echo "  login      - Login to Docker Hub"
	@echo ""
	@echo "Image: $(IMAGE_NAME):latest and $(IMAGE_NAME):$(BASE_TAG)"

login:
	@echo "Logging in to Docker Hub..."
	@docker login

build:
	@echo "Building Docker image with tags: latest and $(BASE_TAG)"
	@docker build --platform linux/amd64 -t $(IMAGE_NAME):latest -t $(IMAGE_NAME):$(BASE_TAG) $(DOCKERFILE_DIR)
	@echo "✓ Build complete:"
	@echo "  - $(IMAGE_NAME):latest"
	@echo "  - $(IMAGE_NAME):$(BASE_TAG)"

push: build
	@echo "Pushing Docker images to Docker Hub..."
	@docker push $(IMAGE_NAME):latest
	@docker push $(IMAGE_NAME):$(BASE_TAG)
	@echo "✓ Push complete:"
	@echo "  - $(IMAGE_NAME):latest"
	@echo "  - $(IMAGE_NAME):$(BASE_TAG)"

all: push
	@echo "✓ All done!"
