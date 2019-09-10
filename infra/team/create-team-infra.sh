#!/bin/bash

if [[ $# -lt 2 ]]; then
  echo "Usage: ./create-team-infra.sh <TEAM_NAME> <PASSWORD>"
  exit 1
fi

if [[ -z "${ORGANIZATION_ID}" ]]; then
  echo "ORGANIZATION_ID env var must be set"
  exit 2
fi

TEAM_NAME=$1
PASSWORD=$2

echo "Creating env for team: ${TEAM_NAME} with password: ${PASSWORD}"

terraform apply \
  -var folder_id=${ORGANIZATION_ID} \
  -var team_name=${TEAM_NAME} \
  -var password=${PASSWORD} \
  -state ksw-${TEAM_NAME}.tfstate \
  ./lab

