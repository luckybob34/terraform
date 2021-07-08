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

module "log_analytics_workspaces" {
  source                     = "./modules/loganalyticsworkspace"
  log_analytics_workspace_rg = var.resource_group_name
  log_analytics_workspaces   = var.log_analytics_workspaces
  environment                = var.environment
}
