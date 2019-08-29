#!/bin/sh

apt update

apt install -y docker.io unzip

curl -LO https://releases.hashicorp.com/terraform/0.12.7/terraform_0.12.7_linux_amd64.zip

unzip terraform_0.12.7_linux_amd64.zip -d /usr/local/bin

curl -L https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl

chmod +x /usr/local/bin/kubectl