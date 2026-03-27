resource "google_compute_global_address" "this" {
  name = "example-lb-ip"

  depends_on = [google_project_service.this["compute.googleapis.com"]]
}

resource "google_compute_region_network_endpoint_group" "api_gateway" {
  provider              = google-beta
  name                  = "example-api-gateway-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  serverless_deployment {
    platform = "apigateway.googleapis.com"
    resource = google_api_gateway_gateway.this.gateway_id
  }

  depends_on = [google_project_service.this["compute.googleapis.com"]]
}

resource "google_compute_backend_service" "this" {
  name                  = "example-backend-service"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"
  security_policy       = google_compute_security_policy.this.id

  backend {
    group = google_compute_region_network_endpoint_group.api_gateway.id
  }
}

resource "google_compute_url_map" "this" {
  name            = "example-url-map"
  default_service = google_compute_backend_service.this.id
}

resource "google_compute_target_http_proxy" "this" {
  name    = "example-http-proxy"
  url_map = google_compute_url_map.this.id
}

resource "google_compute_global_forwarding_rule" "this" {
  name                  = "example-forwarding-rule"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_http_proxy.this.id
  ip_address            = google_compute_global_address.this.id
  port_range            = "80"
}
