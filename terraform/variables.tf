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
