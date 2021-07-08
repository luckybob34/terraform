# -
# - Core object
# -

variable "log_analytics_workspace_rg" {
  description = "The Log Analytics Workspace resources group name."
  type        = string
}

variable "environment" {
  description = "Current environment"
  type        = string
}

# -
# - Main resources
# -
variable "log_analytics_workspaces" {
  description = "Log Analytics Workspaces to create with their configuration"
  type        = any
}