# Remove API Gateway resources from state without destroying them in GCP.
# Delete manually after confirming new architecture works.

removed {
  from = google_api_gateway_gateway.this
  lifecycle {
    destroy = false
  }
}

removed {
  from = google_api_gateway_api_config.this
  lifecycle {
    destroy = false
  }
}

removed {
  from = google_api_gateway_api.this
  lifecycle {
    destroy = false
  }
}

removed {
  from = google_service_account.api_gateway
  lifecycle {
    destroy = false
  }
}

removed {
  from = google_cloud_run_v2_service_iam_member.api_gateway_invoker
  lifecycle {
    destroy = false
  }
}
