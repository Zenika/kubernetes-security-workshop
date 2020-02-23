#!/usr/bin/env sh

set -e

source .env

if [[ $# -lt 1 ]]; then
  echo "Usage: ./create-project.sh <PROJECT_NAME>"
  exit 1
fi
PROJECT=$1

gcloud projects create $PROJECT \
  --folder ${FOLDER}

gcloud alpha billing projects link $PROJECT \
  --billing-account ${BILLING_ACCOUNT}

gcloud projects add-iam-policy-binding $PROJECT \
  --member user:pierre-yves.aillet@zenika.com \
  --role roles/owner

gcloud projects add-iam-policy-binding $PROJECT \
  --member user:eric.briand@zenika.com \
  --role roles/owner

gcloud projects add-iam-policy-binding $PROJECT \
  --member serviceAccount:terraform@${TF_PROJECT}.iam.gserviceaccount.com \
  --role roles/owner

gcloud services enable compute.googleapis.com --project $PROJECT
gcloud services enable iam.googleapis.com --project $PROJECT
gcloud services enable containerregistry.googleapis.com --project $PROJECT
