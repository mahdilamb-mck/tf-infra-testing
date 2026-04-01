resource "google_service_account" "cloud_run" {
  project      = var.project_id
  account_id   = "cloud-run-deployer"
  display_name = "Cloud Run Deployer"
  description  = "Service account for Cloud Run deployment"
}

resource "google_project_iam_member" "cloud_run" {
  for_each = toset([
    "roles/run.developer",
    "roles/iam.serviceAccountUser",
    "roles/storage.objectViewer",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}
