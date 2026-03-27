output "gateway_url" {
  value       = "https://${google_api_gateway_gateway.this.default_hostname}"
  description = "The *.gateway.dev URL of the API gateway."
}

output "load_balancer_ip" {
  value       = google_compute_global_address.this.address
  description = "The static IP address of the load balancer."
}
