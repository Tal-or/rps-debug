REGISTRY ?= quay.io/titzhak
IMG ?= rps-debug
TAG ?= latest

netcat-image-build:
	docker build -f Dockerfile-netcat -t $(REGISTRY)/$(IMG):netcatonly .

netcat-image-push:
	docker push $(REGISTRY)/$(IMG):netcatonly

oslat-image-build:
	docker build -t $(REGISTRY)/$(IMG):$(TAG) .

oslat-image-push:
	docker push $(REGISTRY)/$(IMG):$(TAG)

build:
	mkdir -p _out || :
	go build -mod=vendor -o _out/oslat-runner oslat-runner/main.go