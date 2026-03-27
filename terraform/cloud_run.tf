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
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"

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
      template[0].scaling,
      scaling,
    ]
  }
}
