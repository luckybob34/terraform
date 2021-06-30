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
# - Main Resources
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
  type        = any
}

variable "subnets" {
  description = "Subnets to create with their configurations"
  type        = any
}

variable "route_tables" {
  description = "Route Tables to create with their configurations"
  type        = any
}

variable "route_table_association" {
  description = "Route Table Association to Subnet"
  type        = any
}

variable "network_security_group_association" {
  description = "Network Security Group to Subnet"
  type        = any
}
