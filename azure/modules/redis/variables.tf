# -
# - Core object
# -
variable "redis_cache_location" {
  description = "Redis Cache resources location if different that the resource group's location."
  type        = string
  default     = ""
}

variable "redis_cache_rg" {
  description = "The Redis Cache resources group name."
  type        = string
}

variable "environment" {
  description = "Current environment"
  type        = string
}
# -
# - Main resources
# -
variable "redis_cache" {
  description = "The Redis Cache with their properties."
  type        = any
}

# -
# - Other
# -
variable "null_array" {
  description = ""
  default     = []
}