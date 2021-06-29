# -
# - Core object
# -
variable "key_vault_location" {
  description = "Key Vault resources location if different that the resource group's location."
  type        = string
  default     = ""
}

variable "key_vault_rg" {
  description = "The Key Vault resources group name."
  type        = string
}

variable "environment" {
  description = "Current environment"
  type        = string
}
# -
# - Main resources
# -
variable "key_vaults" {
  description = "The Key Vaults with their properties."
  type        = any
}

# -
# - Logging resources
# -
variable "storage_account" {
  description = "The Storage Account for Key Vault Logging"
  type        = any
}

variable "log_analytics_workspace" {
  description = "The Log Analytic Workspace for the Key Vault"
  type        = any
}

variable "monitoring_diagnostic_settings" {
  description = "The Monitoring Diagnostic Setting"
  type        = any
}


# -
# - Other
# -
variable "null_array" {
  description = ""
  default     = []
}