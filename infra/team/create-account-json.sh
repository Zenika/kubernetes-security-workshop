#!/usr/bin/env sh

set -e

source .env

gcloud iam service-accounts keys create account.json \
  --iam-account terraform@${TF_PROJECT}.iam.gserviceaccount.com
