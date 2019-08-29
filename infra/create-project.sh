#!/bin/sh

source .env
PROJECT=${1:-ksw-team1}

gcloud projects create $PROJECT \
  --folder ${FOLDER}

gcloud alpha billing projects link $PROJECT \
  --billing-account ${BILLING_ACCOUNT}

gcloud projects add-iam-policy-binding $PROJECT \    
  --member pierre-yves.aillet@zenika.com \
  --role roles/owner

gcloud projects add-iam-policy-binding $PROJECT \    
  --member eric.briand@zenika.com \
  --role roles/owner

gcloud projects add-iam-policy-binding $PROJECT \    
  --member serviceAccount:terraform@${PROJECT}.iam.gserviceaccount.com \
  --role roles/owner

gcloud services enable compute.googleapis.com --project $PROJECT
gcloud services enable iam.googleapis.com --project $PROJECT
gcloud services enable containerregistry.googleapis.com --project $PROJECT