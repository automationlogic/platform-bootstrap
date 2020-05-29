#!/bin/bash

# Check credentials
echo "Checking for active credentials ..."
gcloud auth list | grep -qe "ACTIVE\s*ACCOUNT"
if [ $? -ne 0 ]; then
  gcloud auth login --no-launch-browser
fi

echo "Checking for active application-default credentials ..."
gcloud auth application-default print-access-token >/dev/null 2>&1
if [ $? -ne 0 ]; then
  gcloud auth application-default login --no-launch-browser
fi

# Set variables

source _start_vars.sh

# Prepare the environment

echo "Checking if bootstrap project exists ..."
gcloud projects list | awk '{ print $1 }' | grep -q ^"${BOOTSTRAP_PROJECT}"$
if [ $? -ne 0 ]; then
  echo "Bootstrap project does not exist."
  echo "Making bootstrap project ..."
  gcloud projects create ${BOOTSTRAP_PROJECT}
fi

echo "Checking if bootstrap terraform state bucket exists ..."
gsutil ls -p ${BOOTSTRAP_PROJECT} | grep -q gs://${STATE_BUCKET}/
if [ $? -ne 0 ]; then
  echo "Bootstrap terraform state bucket does not exist."
  echo "Linking billing account to project ..."
  gcloud beta billing projects link ${BOOTSTRAP_PROJECT} --billing-account ${BILLING_ACCOUNT}
  echo "Change to bootstrap project ..."
  gcloud config set project ${BOOTSTRAP_PROJECT}
  echo "Sleep to take effect ..."
  sleep 20
  echo "Making storage bucket ..."
  gsutil mb -l ${REGION} -p ${BOOTSTRAP_PROJECT} gs://${STATE_BUCKET}/
fi

# Create infrastructure

source _tf_vars.sh

cd infra

echo "Deploying infrastructure ..."

terraform init \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="prefix=bootstrap"
terraform plan
terraform apply -auto-approve
if [ $? -ne 0 ]; then
  echo
  echo "Have a look at the terraform error."
  echo "If you are required to connect the github repo, follow the instructions."
  echo "For example, the first time around the trigger has to be connected to the repo,"
  echo "and you have to manually navigate your browser to:"
  echo "https://console.cloud.google.com/cloud-build/triggers/connect?project=<bootstrap project number>"
  exit 0
fi
cd -

# Display order for further deployment

echo
echo "DONE!"
echo "${BOOTSTRAP_PROJECT} has been created with a trigger for infrastructure"
echo "Now proceed as follows:"
echo "1. Trigger the infrastructure build (creates infrastructure + triggers)"
echo "2. Trigger relevant service and security builds (via triggers created in 1)"
