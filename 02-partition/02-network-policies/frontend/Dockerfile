FROM golang:1.12.1

WORKDIR /go/frontend

COPY . .
RUN CGO_ENABLED=0 go build -o frontend .

FROM debian:10 
RUN apt update && apt install -y curl
COPY --from=0 /go/frontend/frontend /frontend
COPY index.html index.html
EXPOSE 80
ENTRYPOINT ["/frontend"]
