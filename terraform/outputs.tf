output "load_balancer_ip" {
  value       = google_compute_global_address.this.address
  description = "The static IP address of the load balancer."
}
