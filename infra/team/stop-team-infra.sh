#!/bin/bash

PROJECT_ID=kubernetes-security-workshop
ZONE=europe-west1-c

if [[ $# -lt 1 ]]; then
  echo "Usage: ./stop-team-infra.sh <TEAM_NAME>"
  exit 1
fi
TEAM_PROJECT_ID=$1


gcloud auth activate-service-account \
  --project=${PROJECT_ID} --key-file=account.json

gcloud compute instances stop -q \
	$(gcloud compute instances list --project ${TEAM_PROJECT_ID} --format="value(name)") \
	--project=${TEAM_PROJECT_ID} --zone ${ZONE}
