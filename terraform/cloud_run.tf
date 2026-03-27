locals {
  envoy_config = <<-YAML
    static_resources:
      listeners:
        - name: listener_0
          address:
            socket_address:
              address: 0.0.0.0
              port_value: 8080
          filter_chains:
            - filters:
                - name: envoy.filters.network.http_connection_manager
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                    stat_prefix: ingress_http
                    route_config:
                      name: local_route
                      virtual_hosts:
                        - name: backend
                          domains: ["*"]
                          routes:
                            - match:
                                prefix: "/"
                              route:
                                cluster: app
                    http_filters:
                      - name: envoy.filters.http.jwt_authn
                        typed_config:
                          "@type": type.googleapis.com/envoy.extensions.filters.http.jwt_authn.v3.JwtAuthentication
                          providers:
                            google_id_token:
                              issuer: "https://accounts.google.com"
                              audiences:
                                - "${var.google_audience}"
                              remote_jwks:
                                http_uri:
                                  uri: "https://www.googleapis.com/oauth2/v3/certs"
                                  cluster: google_jwks
                                  timeout: 5s
                                cache_duration: 600s
                              from_headers:
                                - name: Authorization
                                  value_prefix: "Bearer "
                          rules:
                            - match:
                                prefix: "/"
                              requires:
                                provider_name: google_id_token
                      - name: envoy.filters.http.router
                        typed_config:
                          "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
      clusters:
        - name: app
          type: STATIC
          load_assignment:
            cluster_name: app
            endpoints:
              - lb_endpoints:
                  - endpoint:
                      address:
                        socket_address:
                          address: 127.0.0.1
                          port_value: 8081
        - name: google_jwks
          type: STRICT_DNS
          load_assignment:
            cluster_name: google_jwks
            endpoints:
              - lb_endpoints:
                  - endpoint:
                      address:
                        socket_address:
                          address: www.googleapis.com
                          port_value: 443
          transport_socket:
            name: envoy.transport_sockets.tls
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
              sni: www.googleapis.com
  YAML
}

resource "google_service_account" "cloud_run" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"

  depends_on = [google_project_service.this["iam.googleapis.com"]]
}

# resource "google_project_iam_member" "cloud_run_discovery_engine" {
#   project = var.project_id
#   role    = "roles/discoveryengine.viewer"
#   member  = "serviceAccount:${google_service_account.cloud_run.email}"
# }

resource "google_cloud_run_v2_service" "this" {
  name                = "example-service"
  location            = var.region
  project             = var.project_id
  ingress             = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  deletion_protection = false

  depends_on = [google_project_service.this["run.googleapis.com"]]

  template {
    service_account  = google_service_account.cloud_run.email
    session_affinity = true
    scaling {
      max_instance_count = 1
    }

    # Envoy sidecar — JWT validation
    containers {
      name  = "envoy"
      image = "envoyproxy/envoy:v1.31-latest"

      ports {
        container_port = 8080
      }

      args = ["--config-yaml", local.envoy_config]
    }

    # Application container
    containers {
      name  = "app"
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      env {
        name  = "PORT"
        value = "8081"
      }

      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
      }

      env {
        name  = "VERTEX_APP_ENGINE_ID"
        value = google_discovery_engine_search_engine.this.engine_id
      }
    }

    labels = {
      datastore_ids_hash   = md5(join(",", sort(google_discovery_engine_search_engine.this.data_store_ids)))
      datastore_names_hash = md5(join(",", local.engine_datastore_names))
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      template[0].containers[1].image,
      template[0].scaling,
      scaling,
    ]
  }
}

# Blocked by org policy — cannot grant allUsers access.
# The LB → Cloud Run path works without this when using INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER.
# resource "google_cloud_run_v2_service_iam_member" "allow_unauthenticated" {
#   name     = google_cloud_run_v2_service.this.name
#   location = google_cloud_run_v2_service.this.location
#   role     = "roles/run.invoker"
#   member   = "allUsers"
# }
