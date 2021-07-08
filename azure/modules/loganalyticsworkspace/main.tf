# -
# - Data gathering
# -
data "azurerm_resource_group" "rg" {
  name = var.log_analytics_workspace_rg
}

# -
# - Log Analytics Workspace
# -
resource "azurerm_log_analytics_workspace" "law1" {
  for_each                          = var.log_analytics_workspaces
  name                              = "${var.environment}-${each.value["name"]}-law"                       #(Required) Specifies the name of the Log Analytics Workspace. Workspace name should include 4-63 letters, digits or '-'. The '-' shouldn't be the first or the last symbol. Changing this forces a new resource to be created.
  location                          = lookup(each.value, "location", null) == null ? data.azurerm_resource_group.rg.location : each.value["location"] #(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
  resource_group_name               = data.azurerm_resource_group.rg.name                                  #(Required) The name of the resource group in which the Log Analytics workspace is created. Changing this forces a new resource to be created.
  sku                               = lookup(each.value, "sku", null)                                      #(Optional) Specifies the Sku of the Log Analytics Workspace. Possible values are Free, PerNode, Premium, Standard, Standalone, Unlimited, CapacityReservation, and PerGB2018 (new Sku as of 2018-04-03). Defaults to PerGB2018.
  retention_in_days                 = lookup(each.value, "retention_in_days", null)                        #(Optional) The workspace data retention in days. Possible values are either 7 (Free Tier only) or range between 30 and 730.
  daily_quota_gb                    = lookup(each.value, "daily_quota_gb", null)                           #(Optional) The workspace daily quota for ingestion in GB. Defaults to -1 (unlimited) if omitted.
  internet_ingestion_enabled        = lookup(each.value, "internet_ingestion_enabled", null)               #(Optional) Should the Log Analytics Workflow support ingestion over the Public Internet? Defaults to true.
  internet_query_enabled            = lookup(each.value, "internet_query_enabled", null)                   #(Optional) Should the Log Analytics Workflow support querying over the Public Internet? Defaults to true.
  reservation_capcity_in_gb_per_day = lookup(each.value, "reservation_capcity_in_gb_per_day", null)        #(Optional) The capacity reservation level in GB for this workspace. Must be in increments of 100 between 100 and 5000.

  tags = merge(data.azurerm_resource_group.rg.tags, lookup(each.value, "tags", []))
}