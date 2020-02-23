#!/bin/sh

apt update

apt install -y docker.io unzip

curl -LO https://releases.hashicorp.com/terraform/0.12.7/terraform_0.12.7_linux_amd64.zip

unzip terraform_0.12.7_linux_amd64.zip -d /usr/local/bin

curl -L https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl

chmod +x /usr/local/bin/kubectl

export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get install google-cloud-sdk
