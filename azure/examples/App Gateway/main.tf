terraform {
  backend "azurerm" {}
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
# - Resource Group
# -
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.resource_tags
}

# -
# - Virtual Network, User Defined Routes and Network Security Groups
# - 
module "virtual_networks" {
  depends_on                         = [azurerm_resource_group.rg]
  source                             = "./modules/virtualnetwork"
  network_rg                         = var.resource_group_name
  environment                        = var.environment  
  existing_ddos_protection_plans     = {}
  existing_network_security_groups   = {}
  ddos_protection_plans              = {}
  network_security_groups            = var.network_security_groups
  route_tables                       = {}
  virtual_networks                   = var.virtual_networks
  subnets                            = var.subnets
  route_table_association            = {}
  network_security_group_association = var.network_security_group_association
}

# -
# - Application Gateway
# - 
module "application_gateways" {
  depends_on                 = [azurerm_resource_group.rg, module.virtual_networks]
  source                     = "./modules/appgateway"
  app_gateway_rg             = var.resource_group_name
  environment                = var.environment
  existing_virtual_networks  = module.virtual_networks.virtual_networks
  existing_subnets           = module.virtual_networks.subnets
  existing_public_ips        = {}
  public_ips                 = var.public_ips
  app_gateways               = var.application_gateways
}
