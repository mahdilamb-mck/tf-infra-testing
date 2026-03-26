resource "google_discovery_engine_data_store" "this" {
  location                    = var.location
  data_store_id               = "example-datastore"
  display_name                = "Example Datastore"
  industry_vertical           = "GENERIC"
  content_config              = "CONTENT_REQUIRED"
  solution_types              = ["SOLUTION_TYPE_SEARCH"]
  create_advanced_site_search = false

  depends_on = [google_project_service.this["discoveryengine.googleapis.com"]]

  lifecycle {
    ignore_changes = [
      document_processing_config,
    ]
  }
}

resource "google_discovery_engine_search_engine" "this" {
  engine_id     = "example-search-engine"
  collection_id = "default_collection"
  location      = google_discovery_engine_data_store.this.location
  display_name  = "Example Search Engine"

  data_store_ids = [google_discovery_engine_data_store.this.data_store_id]

  search_engine_config {
    search_tier    = "SEARCH_TIER_STANDARD"
    search_add_ons = ["SEARCH_ADD_ON_LLM"]
  }
}

locals {
  datastore_map          = { for ds in [google_discovery_engine_data_store.this] : ds.data_store_id => ds }
  engine_datastore_names = [for id in sort(google_discovery_engine_search_engine.this.data_store_ids) : local.datastore_map[id].display_name]
}

resource "google_cloud_run_v2_service" "this" {
  name                = "example-service"
  location            = var.region
  project             = var.project_id
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  depends_on = [google_project_service.this["run.googleapis.com"]]

  template {
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
    ]
  }
}

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
        cloud_run_url    = google_cloud_run_v2_service.this.uri
        gateway_audience = "https://${google_api_gateway_gateway.this.default_hostname}"
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
