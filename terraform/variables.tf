variable "project_id" {
  type        = string
  description = "The ID of the GCP project."
}

variable "location" {
  type        = string
  default     = "eu"
  description = "The location to create resources in."
}

variable "region" {
  type        = string
  default     = "europe-west2"
  description = "The region to create resources in."
}

variable "gateway_url" {
  type        = string
  default     = ""
  description = "The *.gateway.dev URL of the API gateway. Leave empty on first deploy; set after the gateway is created."
}
