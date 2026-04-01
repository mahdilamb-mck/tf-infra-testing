data "google_project" "this" {
  project_id = var.project_id
}


module "envoy_example" {
  source         = "./tf-gcp-cloud-run-envoy-module"
  project_id     = var.project_id
  storage_bucket = "proj-01kmnxrw0amwv-envoy-configs"
  okta_domain    = "trial-4290922.okta.com"
  okta_audience  = "lillik-kaas-sbx"
  cloud_run = {
    name            = "test-cloud-run-service"
    location        = var.region
    image           = "us-docker.pkg.dev/cloudrun/container/hello"
    service_account = google_service_account.cloud_run.email
  }
}
