resource "google_organization_iam_member" "cloud_build" {
  org_id = var.org_id
  for_each = toset([
    "roles/storage.admin",
    "roles/billing.user",
    "roles/cloudbuild.builds.editor",
    "roles/resourcemanager.projectCreator",
    "roles/accesscontextmanager.policyAdmin"
  ])

  role = each.key

  member = "serviceAccount:${var.orchestration_project_number}@cloudbuild.gserviceaccount.com"
}
