# -
# - Log Analytics Workspaces
# -

output "log_analytics_workspaces" {
  description = "Map output of the Log Analytics Workspaces"
  value       = { for k, b in azurerm_log_analytics_workspace.law1 : k => b }
}