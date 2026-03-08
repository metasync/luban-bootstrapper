include Makefile.env

FULL_IMAGE_NAME := $(IMAGE_REGISTRY)/$(IMAGE_NAMESPACE)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: all build push shell

all: build

build:
	docker build \
		--build-arg BASE_IMAGE_NAME=$(BASE_IMAGE_NAME) \
		--build-arg BASE_IMAGE_TAG=$(BASE_IMAGE_TAG) \
		--build-arg UV_VERSION=$(UV_VERSION) \
		--build-arg JUPYTER_SERVER_PROXY_VERSION=$(JUPYTER_SERVER_PROXY_VERSION) \
		--platform linux/amd64 \
		-t $(FULL_IMAGE_NAME) .

push:
	docker push $(FULL_IMAGE_NAME)

shell:
	docker run --rm -it -p 8888:8888 $(FULL_IMAGE_NAME) /bin/bash
