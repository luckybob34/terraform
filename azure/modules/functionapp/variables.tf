# -
# - Core object
# -
variable "function_app_location" {
  description = "App Service resources location if different that the resource group's location."
  type        = string
  default     = ""
}

variable "function_app_rg" {
  description = "The App Service resources group name."
  type        = string
}
variable existing_storage_accounts {
  description = "The existing Storage Accounts"
  type        = any
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

variable "function_apps" {
  description = "The Function Apps with their properties."
  type        = any
}

variable "storage_accounts" {
  description = "The Storage Accounts with thier properties"
}

# -
# - Other
# -
variable "null_array" {
  description = ""
  default     = []
}