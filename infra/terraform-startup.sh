#!/bin/sh

apt update

apt install -y docker.io unzip

curl -LO https://releases.hashicorp.com/terraform/0.12.7/terraform_0.12.7_linux_amd64.zip

unzip terraform_0.12.7_linux_amd64.zip -d /usr/local/bin
