terraform {
  backend "local" {}
  required_providers {
    azurerm = {
      source  = "azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
    features {}
}

# -
# - Resource Group Lock
# - Only Applies the lock on production environement 
resource "azurerm_management_lock" "rg" {
 name       = var.resource_group_lock
 scope      = azurerm_resource_group.rg.id
 lock_level = "CanNotDelete"
 notes      = "Locked for compliance"
 count      = var.environment == "prod" ? 1 : 0
}

# -
# - Resource Group
# -
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.resource_tags
}

# -
# - Virtual Networks
# -
module "virtual_networks" {
  depends_on                       = [azurerm_resource_group.rg]
  source                           = "git::github.com/luckybob34/terraform.git//azure/modules/virtualnetwork"
  network_rg                       = var.resource_group_name
  environment                      = var.environment  
  existing_ddos_protection_plans   = {}
  existing_network_security_groups = {}
  ddos_protection_plans            = var.ddos_protection_plans
  network_security_groups          = var.network_security_groups
  virtual_networks                 = var.virtual_networks
}
