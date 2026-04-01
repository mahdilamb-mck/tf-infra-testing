variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "storage_bucket" {
  description = "Location to store the configs"
  type        = string
}

##### Envoy Config #####

variable "okta_domain" {
  description = "Okta domain for JWT authentication"
  type        = string
  default     = "mckinsey.okta.com"
}

variable "okta_auth_server_id" {
  description = "Okta authorization server ID"
  type        = string
  default     = "default"
}

variable "okta_audience" {
  description = "Expected audience in the Okta JWT"
  type        = string
}

##### Cloud Run #####

variable "cloud_run" {
  description = "Cloud Run service configuration"
  type = object({
    name     = string
    location = string
    image    = string
    port     = optional(number, 8080)
    envs     = optional(map(string), {})
    secrets = optional(map(object({
      secret  = string
      version = optional(string, "latest")
    })), {})
    limits = optional(object({
      cpu    = optional(string, "1000m")
      memory = optional(string, "512Mi")
    }), {})
    scaling = optional(object({
      min_instance_count = optional(number, 0)
      max_instance_count = optional(number, 1)
    }), {})
    service_account = string
    ingress         = optional(string, "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER")
  })
}
