# -
# - Function Apps
# -

output "function_apps" {
  description = "Map output of the Function Apps"
  value       = { for k, b in azurerm_function_app.apps1 : k => b }
}

# -
# - App Service Plans - Map outputs
# -

output "app_service_plans" {
  description = "Map output of the App Service Plans"
  value       = { for k, b in azurerm_app_service_plan.asp1 : k => b }
}

# -
# - Storage Accounts - Map outputs
# -

output "storage_accounts" {
  description = "Map output of the Storage Accounts"
  value       = { for k, b in azurerm_storage_account.sa1 : k => b }
}