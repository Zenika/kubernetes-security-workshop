.PHONY: clean build run

build:
	docker image build -t eu.gcr.io/kubernetes-security-workshop/rails-with-cve .

run: build
	docker container run -d --rm --name rails-with-cve -p 3000:3000 eu.gcr.io/kubernetes-security-workshop/rails-with-cve

clean:
	docker container stop rails-with-cve
	docker image rm -f eu.gcr.io/kubernetes-security-workshop/rails-with-cve
