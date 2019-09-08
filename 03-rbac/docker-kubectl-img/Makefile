.PHONY: build push

default: build

build:
	docker build . -t "eu.gcr.io/kubernetes-security-workshop/kubectl:v1.15.0"

push:
	docker push "eu.gcr.io/kubernetes-security-workshop/kubectl:v1.15.0"