# -
# - Core object
# -
variable "app_service_location" {
  description = "App Service resources location if different that the resource group's location."
  type        = string
  default     = ""
}

variable "app_service_rg" {
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
variable "app_service_plans" {
  description = "The App Services plans with their properties."
  type        = any
}

variable "app_services" {
  description = "The App Services with their properties."
  type        = any
}

variable "site_extensions" {
  description = "Site Extensions for the App Services with their properties"
  type        = any
}

variable "monitor_autoscale_settings" {
  description = "The Autoscale settings for the App Service Plans and App Services with thier properties"
  type        = any
}


# -
# - Other
# -
variable "null_array" {
  description = ""
  default     = []
}