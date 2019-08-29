#!/bin/sh

gcloud iam service-accounts create terraform \
  --display-name "Terraform" --project kubernetes-security-workshop

gcloud iam service-accounts keys create account.json \
  --iam-account terraform@kubernetes-security-workshop.iam.gserviceaccount.com
