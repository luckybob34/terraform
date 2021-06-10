# -
# - CosmosDB - Map Outputs
# -

output "cosmosdb_accounts" {
  description = "Map output of the CosmosDB Account"
  value       = { for k, b in azurerm_cosmosdb_account.cdba1 : k => b }
}

# -
# - CosmosDB - SQL Database - Map Outputs
# -

output "cosmosdb_sql_databases" {
  description = "Map output of the CosmosDB SQL Databases"
  value       = { for k, b in azurerm_cosmosdb_sql_database.sql1 : k => b }
}