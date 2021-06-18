# -
# - Core object
# -
variable "storage_account_location" {
  description = "App Service resources location if different that the resource group's location."
  type        = string
  default     = ""
}

variable "storage_account_rg" {
  description = "The Storage Account resources group name."
  type        = string
}

variable "environment" {
  description = "Current environment"
  type        = string
}
# -
# - Main resources
# -
variable "storage_accounts" {
  description = "The Storage Accounts with their properties."
  type        = any
}

# -
# - Other
# -
variable "null_array" {
  description = ""
  default     = []
}