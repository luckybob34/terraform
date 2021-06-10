# -
# - Core object
# -
variable "traffic_manager_rg" {
  description = "The App Service resources group name."
  type        = string
}

variable "environment" {
  description = "Current environment"
  type        = string
}
# -
# - Main resources
# -
variable "traffic_manager_profiles" {
  description = "The Traffic Manager Profiles with their properties."
  type        = any
}

variable "traffic_manager_endpoints" {
  description = "The Traffic Manager Endpoints with their properties."
  type        = any
}

variable "existing_app_services" {
  description = "Existing App Services to include in the Traffic Manager Endpoints"
  type        = any
}

# -
# - Other
# -
variable "null_array" {
  description = ""
  default     = []
}