#!/bin/sh

PROJECT=kubernetes-security-workshop

gcloud iam service-accounts create terraform \
  --display-name "Terraform" --project $PROJECT