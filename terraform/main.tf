data "google_project" "this" {
  project_id = var.project_id
}


module "envoy_example" {
  source         = "./terraform-gcp-cloud-run-envoy"
  project_id     = var.project_id
  storage_bucket = "proj-01kmnxrw0amwv-envoy-configs"
  auth_provider  = "google"
  google_jwt_payload = {
    team = "platform"
    env  = "dev"
  }
  cloud_run = {
    name            = "test-cloud-run-service"
    location        = var.region
    image           = "mccutchen/go-httpbin"
    service_account = "sa-proj-01kmnxrw0amwv@proj-01kmnxrw0amwv.iam.gserviceaccount.com"
    ingress         = "INGRESS_TRAFFIC_ALL"
  }
}
