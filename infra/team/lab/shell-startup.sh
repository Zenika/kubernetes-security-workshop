#!/bin/sh


echo "StrictHostKeyChecking accept-new" >> /etc/ssh/ssh_config
systemctl reload sshd

curl -L https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl

chmod +x /usr/local/bin/kubectl