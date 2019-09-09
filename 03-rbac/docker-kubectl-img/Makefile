.PHONY: build push

default: build

build:
	docker build . -t "eu.gcr.io/kubernetes-security-workshop/kubectl:v1.12.2"

push:
	docker push "eu.gcr.io/kubernetes-security-workshop/kubectl:v1.12.2"
