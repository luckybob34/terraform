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
# - Other
# -
variable "null_array" {
  description = ""
  default     = []
}