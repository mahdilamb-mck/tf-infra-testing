resource "google_project_service" "this" {
  for_each = toset([
    "discoveryengine.googleapis.com",
    "run.googleapis.com",
    "apigateway.googleapis.com",
    "servicecontrol.googleapis.com",
    "servicemanagement.googleapis.com",
    "iam.googleapis.com",
  ])
  service = each.value

  disable_on_destroy = false
}
