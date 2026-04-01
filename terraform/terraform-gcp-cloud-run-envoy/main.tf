locals {
  is_google = var.auth_provider == "google"
  ingress   = var.cloud_run.ingress != "" ? var.cloud_run.ingress : (local.is_google ? "INGRESS_TRAFFIC_ALL" : "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER")

  envoy_vars = {
    auth_provider         = var.auth_provider
    backend_cluster_type  = "STATIC"
    backend_host          = "127.0.0.1"
    backend_port          = var.cloud_run.backend_port
    port                  = var.cloud_run.port
    connect_timeout       = var.connect_timeout
    gcp_project           = var.project_id
    jwt_payload           = var.google_jwt_payload
    okta_domain           = var.okta_domain
    okta_auth_server_id   = var.okta_auth_server_id
    okta_audience         = var.okta_audience
    okta_cids             = var.okta_cids
    scopes                = var.okta_scopes
    mid_domain            = var.mid_domain
    mid_stack_ids         = var.mid_stack_ids
    mid_client_ids        = var.mid_client_ids
    mcp_gateway_issuer    = var.mcp_gateway_issuer
    mcp_gateway_audiences = var.mcp_gateway_audiences
    mcp_gateway_jwks      = var.mcp_gateway_jwks
  }

  envoy_config_content = templatefile("${path.module}/templates/envoy.yaml.tftpl", local.envoy_vars)
  envoy_config_path    = "envoy/${var.cloud_run.name}-${sha256(local.envoy_config_content)}/envoy.yaml"
}

##### Cloud Run #####

resource "google_cloud_run_v2_service" "this" {
  name                = var.cloud_run.name
  location            = var.cloud_run.location
  project             = var.project_id
  ingress             = local.ingress
  deletion_protection = false

  template {
    service_account = var.cloud_run.service_account

    scaling {
      min_instance_count = var.cloud_run.scaling.min_instance_count
      max_instance_count = var.cloud_run.scaling.max_instance_count
    }

    # Application container
    containers {
      name  = "app"
      image = var.cloud_run.image

      resources {
        limits = {
          cpu    = var.cloud_run.limits.cpu
          memory = var.cloud_run.limits.memory
        }
      }

      env {
        name  = "PORT"
        value = tostring(var.cloud_run.backend_port)
      }

      dynamic "env" {
        for_each = var.cloud_run.envs
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.cloud_run.secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret
              version = env.value.version
            }
          }
        }
      }

      startup_probe {
        tcp_socket {
          port = var.cloud_run.backend_port
        }
        initial_delay_seconds = 0
        period_seconds        = 10
        failure_threshold     = 3
        timeout_seconds       = 1
      }
    }

    # Envoy sidecar
    containers {
      name  = "envoy"
      image = "envoyproxy/envoy-distroless:v1.34-latest"

      depends_on = ["app"]

      args = ["--config-path", "/etc/envoy-config/${local.envoy_config_path}", "--log-level", "info"]

      ports {
        container_port = var.cloud_run.port
      }

      volume_mounts {
        name       = "envoy-config"
        mount_path = "/etc/envoy-config"
      }
    }

    volumes {
      name = "envoy-config"
      gcs {
        bucket    = var.storage_bucket
        read_only = true
      }
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  depends_on = [google_storage_bucket_object.envoy_config]

  lifecycle {
    precondition {
      condition     = local.is_google || local.ingress != "INGRESS_TRAFFIC_ALL"
      error_message = "INGRESS_TRAFFIC_ALL is only allowed with auth_provider = \"google\"."
    }

    ignore_changes = [
      template[0].containers[0].image,
      template[0].revision
    ]
  }
}

# Okta/MID: allow unauthenticated at Cloud Run level so the Authorization
# header is forwarded intact to Envoy, which handles JWT validation.
resource "google_cloud_run_v2_service_iam_member" "allow_unauthenticated" {
  count    = local.is_google ? 0 : 1
  project  = var.project_id
  location = google_cloud_run_v2_service.this.location
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

##### Envoy Config #####

resource "google_storage_bucket_object" "envoy_config" {
  name    = local.envoy_config_path
  bucket  = var.storage_bucket
  content = local.envoy_config_content
}
