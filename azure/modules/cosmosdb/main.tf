# -
# - Data gathering
# -
data "azurerm_resource_group" "rg" {
  name = var.cosmosdb_rg
}

# -
# - CosmosDB Account
# -

resource "azurerm_cosmosdb_account" "cdba1" {
  for_each                  = var.cosmosdb_accounts
  name                      = "cosmosdb-${each.value["name"]}-${var.environment}" #(Required) Specifies the name of the CosmosDB Account. Changing this forces a new resource to be created.
  location                  = var.cosmosdb_location                               #(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
  resource_group_name       = data.azurerm_resource_group.rg.name                 #(Required) The name of the resource group in which the CosmosDB Account is created. Changing this forces a new resource to be created.
  offer_type                = each.value["offer_type"]                            #(Required) Specifies the Offer Type to use for this CosmosDB Account - currently this can only be set to Standard.
  kind                      = lookup(each.value, "kind", null)                    #(Optional) Specifies the Kind of CosmosDB to create - possible values are GlobalDocumentDB and MongoDB. Defaults to GlobalDocumentDB. Changing this forces a new resource to be created.
  
  consistency_policy {                                                            #(Required) Specifies a consistency_policy resource, used to define the consistency policy for this CosmosDB account.
    consistency_level       = each.value["consistency_level"]                     #(Required) The Consistency Level to use for this CosmosDB Account - can be either BoundedStaleness, Eventual, Session, Strong or ConsistentPrefix.
    max_interval_in_seconds = lookup(each.value, "max_interval_in_seconds", null) #(Optional) When used with the Bounded Staleness consistency level, this value represents the time amount of staleness (in seconds) tolerated. Accepted range for this value is 5 - 86400 (1 day). Defaults to 5. Required when consistency_level is set to BoundedStaleness.
    max_staleness_prefix    = lookup(each.value, "max_staleness_prefix", null)    #(Optional) When used with the Bounded Staleness consistency level, this value represents the number of stale requests tolerated. Accepted range for this value is 10 – 2147483647. Defaults to 100. Required when consistency_level is set to BoundedStaleness.
  }

  geo_location {                                                                  #(Required) Specifies a geo_location resource, used to define where data should be replicated with the failover_priority 0 specifying the primary location. 
    prefix                  = lookup(each.value, "prefix", null)                  #(Optional) The string used to generate the document endpoints for this region. If not specified it defaults to ${cosmosdb_account.name}-${location}. Changing this causes the location to be deleted and re-provisioned and cannot be changed for the location with failover priority 0.
    location                = var.cosmosdb_location                               #(Required) The name of the Azure region to host replicated data.
    failover_priority       = 0                                                   #(Required) The failover priority of the region. A failover priority of 0 indicates a write region. The maximum value for a failover priority = (total number of regions - 1). Failover priority values must be unique for each of the regions in which the database account exists. Changing this causes the location to be re-provisioned and cannot be changed for the location with failover priority 0.
    zone_redundant          = lookup(each.value, "zone_redundant", null)          #(Optional) Should zone redundancy be enabled for this region? Defaults to false.
  }

  dynamic "geo_location" {                                                        #(Optional) Additional geo_locations for failover
    for_each = lookup(each.value, "geo_location", [])                           
    content {
      prefix                = lookup(geo_location,value, "prefix", null)                    #(Optional) The string used to generate the document endpoints for this region. If not specified it defaults to ${cosmosdb_account.name}-${location}. Changing this causes the location to be deleted and re-provisioned and cannot be changed for the location with failover priority 0.
      location              = lookup(geo_location.value, "location", null)                  #(Required) The name of the Azure region to host replicated data.  
      failover_priority     = lookup(geo_location.value, "failover_priority", null)         #(Required) The failover priority of the region. A failover priority of 0 indicates a write region. The maximum value for a failover priority = (total number of regions - 1). Failover priority values must be unique for each of the regions in which the database account exists. Changing this causes the location to be re-provisioned and cannot be changed for the location with failover priority 0.
      zone_redundant        = lookup(gep_location.value, "zone_redundant", null)            #(Optional) Should zone redundancy be enabled for this region? Defaults to false.
    }
  }
  
  enable_free_tier              = lookup(each.value, "enable_free_tier", null)              #(Optional) Enable Free Tier pricing option for this Cosmos DB account. Defaults to false. Changing this forces a new resource to be create
  analytical_storage_enabled    = lookup(each.value, "analytical_storage_enabled", null)    #(Optional) Enable Analytical Storage option for this Cosmos DB account. Defaults to false. Changing this forces a new resource to be created.
  enable_automatic_failover     = lookup(each.value, "enable_automatic_failover", null)     #(Optional) Enable automatic fail over for this Cosmos DB account.
  public_network_access_enabled = lookup(each.value, "public_network_access_enabled", null) #(Optional) Whether or not public network access is allowed for this CosmosDB account. 
  
  dynamic "capabilities" {
    for_each = lookup(each.value, "capabilities", [])
    content {
        name                    = lookup(capabilities.value, "name", null)                  # (Required) The capability to enable - Possible values are AllowSelfServeUpgradeToMongo36, DisableRateLimitingResponses, EnableAggregationPipeline, EnableCassandra, EnableGremlin, EnableMongo, EnableTable, EnableServerless, MongoDBv3.4 and mongoEnableDocLevelTTL.
    }
  }
  
  is_virtual_network_filter_enabled     = lookup(each.value, "is_virtual_network_filter_enabled", null) #(Optional) Enables virtual network filtering for this Cosmos DB account.
  key_vault_key_id                      = lookup(each.value, "key_vault_key_id ", null)       #(Optional) A versionless Key Vault Key ID for CMK encryption. Changing this forces a new resource to be created.
  # virtual_network_rule                  = lookup(each.value, "virtual_network_rule ", null)   #(Optional) Specifies a virtual_network_rules resource, used to define which subnets are allowed to access this CosmosDB account.
  enable_multiple_write_locations       = lookup(each.value, "enable_multiple_write_locations", null) #(Optional) Enable multi-master support for this Cosmos DB account.
  access_key_metadata_writes_enabled    = lookup(each.value, "access_key_metadata_writes_enabled", null) #(Optional) Is write operations on metadata resources (databases, containers, throughput) via account keys enabled? Defaults to true.
  mongo_server_version                  = lookup(each.value, "mongo_server_version", null)    #(Optional) The Server Version of a MongoDB account. Possible values are 4.0, 3.6, and 3.2. Changing this forces a new resource to be created.
  network_acl_bypass_for_azure_services = lookup(each.value, "network_acl_bypass_for_azure_services", null) #(Optional) If azure services can bypass ACLs. Defaults to false.
  network_acl_bypass_ids                = lookup(each.value, "network_acl_bypass_ids ", null) #(Optional) The list of resource Ids for Network Acl Bypass for this Cosmos DB account.
  # backup
  # cors_rules
  # identity
  
  tags = data.azurerm_resource_group.rg.tags                                          # (Optional) A mapping of tags to assign to the resource.
}

resource "azurerm_cosmosdb_sql_database" "sql1" {
  depends_on                = [azurerm_cosmosdb_account.cdba1]  
  for_each                  = var.cosmosdb_sql_databases
  name                      = "cosmosdb-sql-${each.value["name"]}-${var.environment}" #(Required) Specifies the name of the CosmosDB SQl Database. Changing this forces a new resource to be created.
  #location                  = var.cosmosdb_location                                   #(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
  resource_group_name       = data.azurerm_resource_group.rg.name                     #(Required) The name of the resource group in which the CosmosDB SQL Database is created. Changing this forces a new resource to be created.
  account_name              = lookup(azurerm_cosmosdb_account.cdba1, each.value["cosmosdb_account_key"])["name"] #(Required) The name of the Cosmos DB SQL Database to create the table within. Changing this forces a new resource to be created.
  throughput                = lookup(each.value, "throuput", null)                    #(Optional) The throughput of SQL database (RU/s). Must be set in increments of 100. The minimum value is 400. This must be set upon database creation otherwise it cannot be updated without a manual terraform destroy-apply. Do not set when azurerm_cosmosdb_account is configured with EnableServerless capability.

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_setting", [])
    content {
      max_throughput        = lookup(autoscale_setting.value, "max_throughput", null) #(Optional) The maximum throughput of the SQL database (RU/s). Must be between 4,000 and 1,000,000. Must be set in increments of 1,000. Conflicts with throughput.
    }
  }
}