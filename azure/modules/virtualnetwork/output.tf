# -
# - Virtual Networks
# -

output "virtual_networks" {
  description = "Map output of the Virtual Networks"
  value       = { for k, b in azurerm_virtual_network.vnet1 : k => b }
}

# -
# - Network Security Groups
# -

output "network_security_groups" {
  description = "Map output of the Network Security Groups"
  value       = { for k, b in azurerm_network_security_group.nsg1 : k => b }
}

# -
# - Subnets
# -

output "subnets" {
  description = "Map output of the Subnets"
  value       = { for k, b in azurerm_subnets.sub1 : k => b }
}

# -
# - Route Tables
# -

output "route_tables" {
  description = "Map output of the Route Tables"
  value       = { for k, b in azurerm_route_table.rt1 : k => b }
}