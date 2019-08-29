#!/bin/sh

gcloud iam service-accounts keys create account.json \
  --iam-account terraform@$PROJECT.iam.gserviceaccount.com
