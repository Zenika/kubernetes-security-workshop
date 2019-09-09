FROM ubuntu:18.04

ENV KUBECTL_VERSION="v1.12.2"

RUN apt update && \
  apt install -y curl && \
  curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl && \
  cp kubectl /usr/local/bin/kubectl && \
  chmod +x /usr/local/bin/kubectl

