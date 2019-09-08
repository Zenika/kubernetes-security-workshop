#!/bin/sh


echo "StrictHostKeyChecking accept-new" >> /etc/ssh/ssh_config
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
systemctl reload sshd
