FROM golang:1.12.1

WORKDIR /go/backend

COPY . .
RUN go get github.com/go-redis/redis
RUN CGO_ENABLED=0 go build -o backend .

FROM debian:10
RUN apt update && apt install -y curl=7.64.0-4 netcat=1.10-41.1
COPY --from=0 /go/backend/backend /backend
EXPOSE 80
ENTRYPOINT ["/backend"]
