#!/bin/sh

PROJECT=kubernetes-security-workshop

gcloud iam service-accounts create terraform \
  --display-name "Terraform" --project $PROJECT

gcloud iam service-accounts keys create account.json \
  --iam-account terraform@$PROJECT.iam.gserviceaccount.com
