.PHONY: clean build run

build:
	docker image build -t rails-with-cve .

run: build
	docker container run -d --rm --name rails-with-cve -p 3000:3000 rails-with-cve

clean:
	docker container stop rails-with-cve
	docker image rm rails-with-cve
