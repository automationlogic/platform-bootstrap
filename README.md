# Platform Bootstrap

## Overview

Bootstrap process for the AL Analytics platform. This repo creates basic GCP resources and a pipeline trigger, using a shell script and Terraform code. The rest of the platform is created by the downstream analytics pipeline.

## Prerequisites

1. terraform >= 0.12
2. bash
3. GCP user account with Organization Admin privileges
4. gcloud auth login
5. gcloud auth application-default login

## Configuration

### Start script variables

Configure `_start_vars.sh` (see also `_start_vars.sh.example`):  

`BOOTSTRAP_PROJECT` : Bootstrap project id  
`STATE_BUCKET` : `"${BOOTSTRAP_PROJECT}-terraform-state"` - Name of bootstrap process terraform state bucket  
`REGION` : Bootstrap project region, eg. `europe-west2`  
`BILLING_ACCOUNT` : Organisation billing account id

### Terraform variables

Configure `_tf_vars.sh` (see also `_tf_vars.sh.example`):  

`TF_VAR_org_id` : `$(gcloud organizations list | tail -1 | awk '{ print $2 }')` - GCP Organisation id  
`GOOGLE_PROJECT` : `"${BOOTSTRAP_PROJECT}"` - Bootstrap project id  
`TF_VAR_orchestration_project_number` : `$(gcloud projects list | awk -v p="${BOOTSTRAP_PROJECT}" '($1 == p) { print $3 }')` - Bootstrap project number  
`TF_VAR_analytics_project` : Analytics project id  
`TF_VAR_region` : `"${REGION}"` - Bootstrap project region  
`TF_VAR_billing_account` : `"${BILLING_ACCOUNT}"` - Organisation billing account id  
`TF_VAR_owner` : Github account name, eg. `automationlogic`  
`TF_VAR_owner_email` : Project owner email  
`TF_VAR_kubeflow_host` : Kubeflow host id (Only available after Kubeflow pipeline creation)  
`TF_VAR_bootstrap_ip`: `$(curl ifconfig.me)`  

## Run

Run the start script:

`bash start.sh`  

## Troubleshooting

### CloudBuild service account does not exist

If you see the following error:

```
Error: Error applying IAM policy for organization "<org number>": Error setting IAM policy for organization "<org number>": googleapi: Error 400: Service account <bootstrap project number>@cloudbuild.gserviceaccount.com does not exist., badRequest

  on iam.tf line 1, in resource "google_organization_iam_member" "cloud_build":
   1: resource "google_organization_iam_member" "cloud_build" {
```

This is likely to be because it takes a short while for the service to create the service account. Run it again.

### Repository mapping does not exist

If you see the following error:

```
Error: Error creating Trigger: googleapi: Error 400: Repository mapping does not exist. Please visit https://console.cloud.google.com/cloud-build/triggers/connect?project=<project_number> to connect a repository to your project

  on triggers.tf line 1, in resource "google_cloudbuild_trigger" "analytics_infra":
   1: resource "google_cloudbuild_trigger" "analytics_infra" {
```

Follow the link in your browser and connect the repo to your project's CloudBuild so that the trigger can trigger on code updates. This needs doing manually because the Github connector needs authorisation first.

**Select your source:** Github (Cloud Build GitHub App) -> Continue  
**Authenticate:** Provide your github credentials -> Authorize Google Cloud Build by Google Cloud Build  
**Select repository:** Edit repositories on GitHub -> Select repositories -> analytics-infra -> Connect repository  
**Create a push trigger:** Skip for now -> Continue  

Rerun the start script:

`bash start.sh`  
