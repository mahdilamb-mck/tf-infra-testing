resource "google_project_service" "enabled_apis" {
  for_each = toset([
    "run.googleapis.com",
  ])

  service = each.value
  project = var.project_id
}
