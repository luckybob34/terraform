# -
# - App Gateway
# -

output "app_gateways" {
  description = "Map output of the App Gateways"
  value       = { for k, b in azurerm_application_gateway.agw1 : k => b }
}

# -
# - Public IPs
# -

output "public_ips" {
  description = "Map output of the Public IPs"
  value       = { for k, b in azurerm_public_ip.pip1 : k => b }
}