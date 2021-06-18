# -
# - Data gathering
# -
data "azurerm_resource_group" "rg" {
  name = var.key_vault_rg
}

data "azurerm_log_analytics_workspace" "law1" {
  count               = var.log_analytics_workspace == null ? 0 : 1
  name                = var.log_analytics_workspace["name"]
  resource_group_name = var.log_analytics_workspace["resource_group_name"]
}

data "azurerm_storage_account" "sa1" {
  count               = var.storage_account == null ? 0 : 1  
  name                = var.storage_account["name"]
  resource_group_name = var.storage_account["resource_group_name"]
}

data "azurerm_client_config" "current" {}

# -
# - Key Vault
# -
resource "azurerm_key_vault" "kv1" {
  for_each            = var.key_vaults
  name                = "kv-${each.value["name"]}-${var.environment}"                              #(Required) Specifies the name of the Key Vault. Changing this forces a new resource to be created.
  resource_group_name = data.azurerm_resource_group.rg.name                                        #(Required) The name of the resource group in which to create the Key Vault. Changing this forces a new resource to be created.
  location            = var.key_vault_location                                                     #(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
  sku_name            = each.value["sku_name"]                                                     #(Required) The Name of the SKU used for this Key Vault. Possible values are standard and premium.  
  tenant_id           = lookup(each.value, "tenat_id", data.azurerm_client_config.current.tenant_id) #(Required) The Azure Active Directory tenant ID that should be used for authenticating requests to the key vault.
  
  dynamic "access_policy" {                                                                        #(Optional) A list of up to 16 objects describing access policies, as described below.
    for_each = lookup(each.value, "access_policy", [])                                    
    content {
      tenant_id               = access_policy.value["tenant_id"]                                   #(Required) The Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Must match the tenant_id used above.
      object_id               = access_policy.value["object_id"]                                   #(Required) The object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies.
      application_id          = lookup(access_policy.value, "application_id  ", null)              #(Optional) The object ID of an Application in Azure Active Directory.
      certificate_permissions = lookup(access_policy.value, "certificate_permissions", null)       #(Optional) List of certificate permissions, must be one or more from the following: Backup, Create, Delete, DeleteIssuers, Get, GetIssuers, Import, List, ListIssuers, ManageContacts, ManageIssuers, Purge, Recover, Restore, SetIssuers and Update.
      key_permissions         = lookup(access_policy.value, "key_permissions", null)               #(Optional) List of key permissions, must be one or more from the following: Backup, Create, Decrypt, Delete, Encrypt, Get, Import, List, Purge, Recover, Restore, Sign, UnwrapKey, Update, Verify and WrapKey.
      secret_permissions      = lookup(access_policy.value, "secret_permissions", null)            #(Optional) List of secret permissions, must be one or more from the following: Backup, Delete, Get, List, Purge, Recover, Restore and Set.
      storage_permissions     = lookup(access_policy.value, "storage_permissions ", null)          #(Optional) List of storage permissions, must be one or more from the following: Backup, Delete, DeleteSAS, Get, GetSAS, List, ListSAS, Purge, Recover, RegenerateKey, Restore, Set, SetSAS and Update.      
    }
  }

  enabled_for_deployment          = lookup(each.value, "enabled_for_deployment", null)             #(Optional) Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault. Defaults to false.
  enabled_for_disk_encryption     = lookup(each.value, "enabled_for_disk_encryption", null)        #(Optional) Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys. Defaults to false.
  enabled_for_template_deployment = lookup(each.value, "enabled_for_template_deployment", null)    #(Optional) Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault. Defaults to false.
  enable_rbac_authorization       = lookup(each.value, "enable_rbac_authorization", null)          #(Optional) Boolean flag to specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization of data actions. Defaults to false.
                                                                                
  dynamic "network_acls" {                                                                         #(Optional) A network_acls block
    for_each = lookup(each.value, "network_acls", [])                                    
    content {
      bypass                     = network_acls.value["bypass"]                                    #(Required) Specifies which traffic can bypass the network rules. Possible values are AzureServices and None.
      default_action             = network_acls.value["default_action"]                            #(Required) The Default Action to use when no rules match from ip_rules / virtual_network_subnet_ids. Possible values are Allow and Deny.
      ip_rules                   = lookup(network_acls.value, "ip_rules", null)                    #(Optional) One or more IP Addresses, or CIDR Blocks which should be able to access the Key Vault.
      virtual_network_subnet_ids = lookup(network_acls.value, "virtual_network_subnet_ids", null)  #(Optional) One or more Subnet ID's which should be able to access this Key Vault.      
    }
  }  

  purge_protection_enabled        = lookup(each.value, "purge_protection_enabled", null)            #(Optional) Is Purge Protection enabled for this Key Vault? Defaults to false.  
  soft_delete_retention_days      = lookup(each.value, "soft_delete_retention_days", null)          #(Optional) The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days.

  dynamic "contact" {                                                                               #(Optional) One or more contact block                            
    for_each = lookup(each.value, "contact", [])                                     
    content {
      email = contact.value["email"]                                                                #(Required) E-mail address of the contact.
      name  = lookup(contact.value, "name", null)                                                   #(Optional) Name of the contact.
      phone = lookup(contact.value, "phone", null)                                                  #(Optional) Phone number of the contact.      
    }   
  }  
  
  tags = data.azurerm_resource_group.rg.tags 
}

resource "azurerm_monitor_diagnostic_setting" "mds1" {
  for_each = var.monitoring_diagnostic_settings
  name                           = "mds-${each.value["name"]}-${var.environment}"                   #(Required) Specifies the name of the Diagnostic Setting. Changing this forces a new resource to be created.
  target_resource_id             = lookup(azurerm_key_vault.kv1, each.value["resource_key"])["id"] #(Required) The ID of an existing Resource on which to configure Diagnostic Settings. Changing this forces a new resource to be created.
  
  eventhub_name                  = lookup(each.value, "eventhub_name", null)                        #(Optional) Specifies the name of the Event Hub where Diagnostics Data should be sent. Changing this forces a new resource to be created.  
  eventhub_authorization_rule_id = lookup(each.value, "eventhub_authorization_rule_id", null)       #(Optional) Specifies the ID of an Event Hub Namespace Authorization Rule used to send Diagnostics Data. Changing this forces a new resource to be created.    
  
  dynamic "log" {                                                                                   #(Optional) One or more log blocks as defined below.
    for_each = lookup(each.value, "log", [])
    content {
      category = log.value["category"]                                                              #(Required) The name of a Diagnostic Log Category for this Resource.
      
      retention_policy {                                                                            #(Optional) A retention_policy block as defined below.
        enabled = log.value["retention_policy_enabled"]                                             #(Required) Is this Retention Policy enabled?
        days    = lookup(log.value, "retention_policy_days", null)                                  #(Optional) The number of days for which this Retention Policy should apply.        
      }      
      
      enabled  = lookup(log.value, "enabled", null)                                                 #(Optional) Is this Diagnostic Log enabled? Defaults to true.    
    }
  }

  log_analytics_workspace_id     = var.log_analytics_workspace != null ? data.azurerm_log_analytics_workspace.law1[0].id : null #(Optional) Specifies the ID of a Log Analytics Workspace where Diagnostics Data should be sent.
  log_analytics_destination_type = lookup(each.value, "", null)                                     #(Optional) When set to 'Dedicated' logs sent to a Log Analytics workspace will go into resource specific tables, instead of the legacy AzureDiagnostics table.
  
  dynamic "metric" {                                                                                #(Optional) One or more metric blocks as defined below.
    for_each = lookup(each.value, "metric", [])
    content {
      category = metric.value["category"]                                                           #(Required) The name of a Diagnostic Metric Category for this Resource.
      
      retention_policy {                                                                            #(Optional) A retention_policy block as defined below.
        enabled = metric.value["retention_policy_enabled"]                                          #(Required) Is this Retention Policy enabled?
        days    = lookup(metric.value, "retention_policy_days", null)                               #(Optional) The number of days for which this Retention Policy should apply.        
      } 
      
      enabled = lookup(metric.value, "enabled", null)                                               #(Optional) Is this Diagnostic Metric enabled? Defaults to true.      
    }
  }

  storage_account_id = var.storage_account != null ? data.azurerm_storage_account.sa1[0].id : null  #(Optional) The ID of the Storage Account where logs should be sent. Changing this forces a new resource to be created    
}