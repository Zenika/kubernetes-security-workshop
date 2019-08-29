#!/bin/sh

PROJECT=kubernetes-security-workshop

gcloud config set project $PROJECT

gcloud compute instances create terraform \
  --service-account=terraform@$PROJECT.iam.gserviceaccount.com \
  --image-project ubuntu-os-cloud \
  --image-family ubuntu-1804-lts \
  --metadata-from-file startup-script=terraform-startup.sh

