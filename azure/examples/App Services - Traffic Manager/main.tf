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
# - App Service Plans & App Services
# -
module "app_services" {
  depends_on                 = [azurerm_resource_group.rg]
  source                     = "github.com/luckybob34/terraform/tree/main/azure/modules/appservice"
  app_service_rg             = var.resource_group_name
  environment                = var.environment
  app_service_plans          = var.app_service_plans
  app_services               = var.app_services
  site_extensions            = var.site_extensions
  monitor_autoscale_settings = var.monitor_autoscale_settings  
}

# -
# - Traffic Manager Profile & Trafic Manager Endpoints
# -
module "traffic_manager" {
  depends_on                = [azurerm_resource_group.rg, module.app_services]
  source                    = "./modules/trafficmanager"
  traffic_manager_rg        = var.resource_group_name
  environment               = var.environment
  traffic_manager_profiles  = var.traffic_manager_profiles
  traffic_manager_endpoints = var.traffic_manager_endpoints
  existing_app_services     = module.app_services.app_services
}
