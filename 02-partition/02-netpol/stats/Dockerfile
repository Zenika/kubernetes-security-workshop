FROM golang:1.12

RUN curl -L https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
  chmod +x /usr/local/bin/kubectl

COPY go.mod go.sum .

RUN go get

COPY main.go

RUN go build .


