output "gateway_url" {
  value       = "https://${google_api_gateway_gateway.this.default_hostname}"
  description = "The *.gateway.dev URL of the API gateway."
}
