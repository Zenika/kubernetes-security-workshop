#!/bin/bash

echo "🚀 Initializing machine"
sudo apt-get update
sudo apt-get install -y docker.io unzip

export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y google-cloud-sdk

gcloud auth configure-docker --quiet

echo "📦 Installing dependencies"
sudo apt-get update
sudo apt-get install -y python3-pip python-pip software-properties-common

echo "📦 Installing ansible"
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt update
sudo apt install -y ansible

echo "🏗 Installing kubespray"
git clone --branch v2.9.0 https://github.com/kubernetes-sigs/kubespray.git

cd kubespray

pip3 install -r requirements.txt
pip install netaddr

echo "🔧 Configuring kubespray"
cp -r inventory/sample inventory/cluster
cp ~/hosts.yml inventory/cluster/hosts.yml
cp ~/k8s-cluster.yml inventory/cluster/group_vars/k8s-cluster/k8s-cluster.yml
cp ~/addons.yml inventory/cluster/group_vars/k8s-cluster/addons.yml
cp ~/all.yml inventory/cluster/group_vars/all/all.yml

echo "☸ Deploying Kubernetes"
ansible-playbook -i inventory/cluster/hosts.yml cluster.yml -b -v --private-key=~/.ssh/id_rsa

sudo cp ~/kubespray/inventory/cluster/artifacts/kubectl /usr/local/bin

mkdir ~/.kube
sudo cp ~/kubespray/inventory/cluster/artifacts/admin.conf ~/.kube/config
sudo chown ubuntu:ubuntu ~/.kube/config

echo "source <(kubectl completion bash)" >> ~/.bashrc

echo "⛑ Installing helm"
wget https://get.helm.sh/helm-v2.13.1-linux-amd64.tar.gz
tar -zxvf helm-v2.13.1-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -f helm-v2.13.1-linux-amd64.tar.gz linux-amd64
helm init --client-only

