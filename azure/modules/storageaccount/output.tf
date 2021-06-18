# -
# - Storage Accounts
# -

output "storage_accounts" {
  description = "Map output of the Key Vaults"
  value       = { for k, b in azurerm_storage_account.sa1 : k => b }
}
