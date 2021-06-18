# -
# - Core object
# -
variable "cosmosdb_rg" {
  description = "The CosmosDB resources group name."
  type        = string
}

variable "cosmosdb_location" {
  description = "The CosmosDB location"
  type        = string
}

variable "environment" {
  description = "Current environment"
  type        = string
}
# -
# - Main resources
# -
variable "cosmosdb_accounts" {
  description = "The CosmosDB Accounts with their properties."
  type        = any
}

variable "cosmosdb_sql_databases" {
  description = "The CosmosDB SQL Databases with their properties."
  type        = any
}

variable "cosmosdb_sql_containers" {
  description = "The CosmosDB SQL Containers with their properties."
  type        = any
}

# -
# - Other
# -
variable "null_array" {
  description = ""
  default     = []
}