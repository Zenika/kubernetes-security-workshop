FROM golang:1.12.1

WORKDIR /go/backend

COPY . .
RUN go get github.com/go-redis/redis
RUN CGO_ENABLED=0 go build -o backend .

FROM gcr.io/distroless/base
COPY --from=0 /go/backend/backend /backend
EXPOSE 80
ENTRYPOINT ["/backend"]
