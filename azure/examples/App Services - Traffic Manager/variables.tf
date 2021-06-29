# -
# - Core object
# -
variable "location" {
  type        = string
  description = "Default resources location"
}
 
variable "resource_group_name" {
  type        = string
  description = "Resource Group to deploy resources"
}

variable "resource_group_lock" {
  type        = string
  description = "The Resource Group lock"
}

variable environment {
  type        = string
  description = "The working environement (dev, uat, prod)"
}

variable resource_tags {
  description = "Tags for the Resource Group and child resources"
}

# -
# - App Services
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
  description = "The Site Extensions with their properties"
  type        = any
}

variable "monitor_autoscale_settings" {
  description = "The Autoscale Settings for the App Service Plan and App Services"
}

# -
# - Traffic Manager Profiles & Traffic Manager Endpoints
# -
variable "traffic_manager_profiles" {
  description = "The Traffic Manager Profiles with their properties."
  type        = any
}

variable "traffic_manager_endpoints" {
  description = "The Traffic Manager Endpoints with their properties."
  type        = any
}