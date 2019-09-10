#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "Usage: ./delete-team-infra.sh <TEAM_NAME>"
  exit 1
fi

if [[ -z "${ORGANIZATION_ID}" ]]; then
  echo "ORGANIZATION_ID env var must be set"
  exit 2
fi

TEAM_NAME=$1
PASSWORD=$2

echo "Deleting env for team: ${TEAM_NAME}"

terraform destroy \
  -var folder_id=${ORGANIZATION_ID} \
  -var team_name=${TEAM_NAME} \
  -var password=${PASSWORD} \
  -state ksw-${TEAM_NAME}.tfstate \
  ./lab

