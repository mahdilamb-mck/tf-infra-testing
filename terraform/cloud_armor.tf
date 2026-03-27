# resource "google_compute_security_policy" "this" {
#   name = "example-security-policy"
#
#   adaptive_protection_config {
#     layer_7_ddos_defense_config {
#       enable = true
#     }
#   }
#
#   # Per-IP rate limiting
#   rule {
#     action   = "throttle"
#     priority = 1000
#
#     match {
#       versioned_expr = "SRC_IPS_V1"
#       config {
#         src_ip_ranges = ["*"]
#       }
#     }
#
#     rate_limit_options {
#       conform_action = "allow"
#       exceed_action  = "deny(429)"
#
#       rate_limit_threshold {
#         count        = 100
#         interval_sec = 60
#       }
#
#       enforce_on_key = "IP"
#     }
#   }
#
#   # Per-API-key rate limiting
#   rule {
#     action   = "throttle"
#     priority = 2000
#
#     match {
#       versioned_expr = "SRC_IPS_V1"
#       config {
#         src_ip_ranges = ["*"]
#       }
#     }
#
#     rate_limit_options {
#       conform_action = "allow"
#       exceed_action  = "deny(429)"
#
#       rate_limit_threshold {
#         count        = 500
#         interval_sec = 60
#       }
#
#       enforce_on_key      = "HTTP_HEADER"
#       enforce_on_key_name = "X-API-Key"
#     }
#   }
#
#   # Default allow rule
#   rule {
#     action   = "allow"
#     priority = 2147483647
#
#     match {
#       versioned_expr = "SRC_IPS_V1"
#       config {
#         src_ip_ranges = ["*"]
#       }
#     }
#   }
#
#   depends_on = [google_project_service.this["compute.googleapis.com"]]
# }
