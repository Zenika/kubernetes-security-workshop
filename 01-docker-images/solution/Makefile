.PHONY: clean build run

build:
	docker image build -t rails-without-cve .

run: build
	docker container run -d --rm --name rails-without-cve -p 3000:3000 rails-without-cve

clean:
	docker container stop rails-without-cve
	docker image rm rails-without-cve
