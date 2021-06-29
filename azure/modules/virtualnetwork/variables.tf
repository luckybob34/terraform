# -
# - Core object
# -

variable "networking_rg" {
  description = "The Virtual Network resources group name."
  type        = string
}

variable "environment" {
  description = "Current environment"
  type        = string
}

# - 
# - Existing Resources
# -
variable "existing_ddos_protection_plans" {
  description = "Existing DDoS Protection Plans in a List with Name and Resource Group"
  type        = any
}

variable "existing_network_security_groups" {
  description = "Existing Network Security Groups in a List with Name and Resource Group"
  type        = any
}

# -
# - Main resources
# -
variable "ddos_protection_plans" {
  description = "DDoS Protection plans to create with their configuration"
  type        = any
}

variable "network_security_groups" {
  description = "Netowrk Security Groups to create with their configuration"
  type        = any
}

variable "virtual_networks" {
  description = "Virtual Networks to create with their configurations"
  type = any
}



# -
# - Other
# -
variable "null_array" {
  description = ""
  default     = []
}