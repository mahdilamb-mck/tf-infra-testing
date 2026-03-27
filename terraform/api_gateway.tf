resource "google_service_account" "api_gateway" {
  account_id   = "api-gateway-sa"
  display_name = "API Gateway Service Account"

  depends_on = [google_project_service.this["iam.googleapis.com"]]
}

resource "google_cloud_run_v2_service_iam_member" "api_gateway_invoker" {
  name     = google_cloud_run_v2_service.this.name
  location = google_cloud_run_v2_service.this.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.api_gateway.email}"
}

resource "google_api_gateway_api" "this" {
  provider = google-beta
  api_id   = "example-api"

  depends_on = [google_project_service.this["apigateway.googleapis.com"]]
}

resource "google_api_gateway_api_config" "this" {
  provider     = google-beta
  api          = google_api_gateway_api.this.api_id
  display_name = "example-api-config"

  openapi_documents {
    document {
      path = "openapi.yaml"
      contents = base64encode(templatefile("${path.module}/templates/openapi.yaml.tpl", {
        cloud_run_url = "https://${google_cloud_run_v2_service.this.name}-${data.google_project.this.number}.${var.region}.run.app"
        gateway_url   = var.gateway_url
      }))
    }
  }

  gateway_config {
    backend_config {
      google_service_account = google_service_account.api_gateway.email
    }
  }

  depends_on = [google_cloud_run_v2_service_iam_member.api_gateway_invoker]

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_api_gateway_gateway" "this" {
  provider   = google-beta
  gateway_id = "example-gateway"
  region     = var.region
  api_config = google_api_gateway_api_config.this.id
}
