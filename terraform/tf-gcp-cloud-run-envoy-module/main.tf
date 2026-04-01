locals {
  envoy_vars = {
    backend_cluster_type = "STATIC"
    backend_host         = "127.0.0.1"
    backend_port         = "9876"
    port                 = "8080"
    okta_domain          = var.okta_domain
    okta_auth_server_id  = var.okta_auth_server_id
    okta_audience        = var.okta_audience
    gcp_project          = var.project_id
  }

  envoy_config_content = templatefile("${path.module}/templates/envoy.yaml.tftpl", local.envoy_vars)
  envoy_config_path    = "envoy/${var.cloud_run.name}-${sha256(local.envoy_config_content)}/envoy.yaml"
}

##### Cloud Run #####

resource "google_cloud_run_v2_service" "this" {
  name                = var.cloud_run.name
  location            = var.cloud_run.location
  project             = var.project_id
  ingress             = var.cloud_run.ingress
  deletion_protection = false

  template {
    service_account = var.cloud_run.service_account

    scaling {
      min_instance_count = var.cloud_run.scaling.min_instance_count
      max_instance_count = var.cloud_run.scaling.max_instance_count
    }

    # Envoy sidecar
    containers {
      name  = "envoy"
      image = "envoyproxy/envoy-distroless:v1.34-latest"

      args = ["--config-path", "/etc/envoy-config/${local.envoy_config_path}"]

      ports {
        container_port = var.cloud_run.port
      }

      volume_mounts {
        name       = "envoy-config"
        mount_path = "/etc/envoy-config"
      }
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
    }

    volumes {
      name = "envoy-config"
      gcs {
        bucket    = var.storage_bucket
        read_only = true
      }
    }
  }

  depends_on = [google_storage_bucket_object.envoy_config]

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      template[0].containers[1].image,
      template[0].revision,
      template[0].labels,
      template[0].annotations,
    ]
  }
}

##### Envoy Config #####

resource "google_storage_bucket_object" "envoy_config" {
  name    = local.envoy_config_path
  bucket  = var.storage_bucket
  content = local.envoy_config_content
}
