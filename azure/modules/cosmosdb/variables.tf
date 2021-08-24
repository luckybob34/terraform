// -
// - General
// -

variable "cosmosdb_rg" {
  description = "The CosmosDB resources group name."
  type        = string
}

variable "environment" {
  description = "Current environment"
  type        = string
}


// -
// - Load Existing Resources
// -
variable "subnets" {
  description = "The Subnets with their properties."
  type        = any
}

variable "log_analytics_workspace" {
  description = "The Log Analytics Workspaces with their properties."
  type        = any
}

// -
// - Resources
// -
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

variable "private_endpoints" {
  description = "The Private Endpoints with their properties."
  type        = any
}

// -
// - Logging
// -
variable "monitor_diagnostic_settings" {
  description = "The Monitor Diagnostic Settings with their properties."
  type        = any
}

// -
// - Other
// -
variable "null_array" {
  description = ""
  default     = []
}