# -
# - Key Vault
# -

output "key_vaults" {
  description = "Map output of the Key Vaults"
  value       = { for k, b in azurerm_key_vault.kv1 : k => b }
}
