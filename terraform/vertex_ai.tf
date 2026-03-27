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
