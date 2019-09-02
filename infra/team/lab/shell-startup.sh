#!/bin/sh


echo "StrictHostKeyChecking accept-new" >> /etc/ssh/ssh_config
systemctl reload sshd
