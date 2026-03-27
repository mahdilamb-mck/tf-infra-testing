resource "google_project_service" "this" {
  for_each = toset([
    "discoveryengine.googleapis.com",
    "run.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
  ])
  service = each.value

  disable_on_destroy = false
}
