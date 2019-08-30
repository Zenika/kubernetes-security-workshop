#!/bin/sh


echo "StrictHostKeyChecking accept-new" >> /etc/ssh/ssh_config
systemctl reload sshd

apt-get update
apt-get install -y docker.io unzip

export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
apt-get update
apt-get install -y google-cloud-sdk

gcloud auth configure-docker --quiet