#!/bin/bash

gcloud auth activate-service-account \
  --project=${PROJECT_ID} --key-file=account.json

PROJECTS=$(gcloud projects list --format='value(project_id)')

for p in $PROJECTS; do
        gcloud compute instances list --project $p --filter=name:shell --format="table[no-heading](tags.items[1],name,networkInterfaces[0].accessConfigs[0].natIP)"
done