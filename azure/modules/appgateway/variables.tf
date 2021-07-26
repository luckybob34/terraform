# -
# - Core object
# -
variable "app_gateway_location" {
  description = "App Service resources location if different that the resource group's location."
  type        = string
  default     = ""
}

variable "app_gateway_rg" {
  description = "The App Gateway resources group name."
  type        = string
}

variable "environment" {
  description = "Current environment"
  type        = string
}
# -
# - Main resources
# -
variable "app_gateways" {
  description = "The App Gateways with their properties."
  type        = any
}

variable "public_ips" {
  description = "The Public Ips with their properties."
  type        = any
}

variable "existing_public_ips" {
  description = "The existing Public Ips"
  type        = any
}

variable "existing_virtual_networks" {
  description = "The Existing Virtual networks"
  type        = any
}

variable "existing_subnets" {
  description = "The existing Subnets"
  type        = any
}

# -
# - Other
# -
variable "null_array" {
  description = ""
  default     = []
}