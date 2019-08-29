.PHONY: clean build run

build:
	docker image build -t eu.gcr.io/kubernetes-security-workshop/rails-without-cve .

run: build
	docker container run -d --rm --name rails-without-cve -p 3000:3000 eu.gcr.io/kubernetes-security-workshop/rails-without-cve

clean:
	docker container stop rails-without-cve
	docker image rm -f eu.gcr.io/kubernetes-security-workshop/rails-without-cve
