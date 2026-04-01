variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "storage_bucket" {
  description = "GCS bucket for envoy configs"
  type        = string
}

variable "auth_provider" {
  description = "Authentication provider. \"google\" for Google JWT, \"okta\" for Okta JWT, \"mid\" for McKinsey ID JWT."
  type        = string

  validation {
    condition     = contains(["google", "okta", "mid", "mcp-gateway"], var.auth_provider)
    error_message = "auth_provider must be \"google\", \"okta\", \"mid\", or \"mcp-gateway\""
  }
}

##### Shared Envoy Config #####

variable "connect_timeout" {
  description = "Envoy backend cluster connect timeout"
  type        = string
  default     = "5s"
}

##### Google #####

variable "google_jwt_payload" {
  description = "Static JWT payload claims to inject via x-jwt-payload header"
  type        = map(string)
  default     = {}
}

##### Okta #####

variable "okta_domain" {
  description = "Okta domain for JWT authentication"
  type        = string
  default     = ""
}

variable "okta_auth_server_id" {
  description = "Okta authorization server ID"
  type        = string
  default     = "default"
}

variable "okta_audience" {
  description = "Expected audience in the Okta JWT"
  type        = string
  default     = ""
}

variable "okta_scopes" {
  description = "Required OAuth scopes for RBAC enforcement"
  type        = list(string)
  default     = []
}

variable "okta_cids" {
  description = "Allowed Okta client IDs for RBAC enforcement"
  type        = list(string)
  default     = []
}

##### MID #####

variable "mid_domain" {
  description = "McKinsey ID domain for JWT authentication"
  type        = string
  default     = ""

  validation {
    condition     = var.mid_domain == "" || contains(["auth.int.mckinsey.id", "auth.mckinsey.id"], var.mid_domain)
    error_message = "mid_domain must be \"auth.int.mckinsey.id\" or \"auth.mckinsey.id\""
  }
}

variable "mid_stack_ids" {
  description = "Allowed MID stack IDs (audience) for user token RBAC"
  type        = list(string)
  default     = []
}

variable "mid_client_ids" {
  description = "Allowed MID client IDs for service token RBAC"
  type        = list(string)
  default     = []
}

##### MCP Gateway #####

variable "mcp_gateway_issuer" {
  description = "JWT issuer URL for the MCP gateway provider"
  type        = string
  default     = ""
}

variable "mcp_gateway_audiences" {
  description = "Expected audiences in the MCP gateway JWT"
  type        = list(string)
  default     = []
}

variable "mcp_gateway_jwks" {
  description = "JWKS JSON string for local JWT validation (inline)"
  type        = string
  default     = ""
  sensitive   = true
}

##### Cloud Run #####

variable "cloud_run" {
  description = "Cloud Run service configuration"
  type = object({
    name         = string
    location     = string
    image        = string
    port         = optional(number, 8080)
    backend_port = optional(number, 8082)
    envs         = optional(map(string), {})
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
    ingress         = optional(string, "")
  })
}
