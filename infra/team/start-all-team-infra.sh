#!/bin/bash

gcloud auth activate-service-account \
  --project=${PROJECT_ID} --key-file=account.json

PROJECTS=$(gcloud projects list --format='value(project_id)')

for p in $PROJECTS; do
	./start-team-infra.sh $p
done
