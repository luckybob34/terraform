/*
    Azure Cosmos DB Module
    Version: 1.0 (Aug 2021)
      
    Loads
      - Resource Group          - Default Resource Group for Resources
      - Subnets                 - Existing Subnets for Network Profile
      - Log Analytics Workspace - Existing Log Analytics Workspace for Monitor Diagnostic Settings

    Resources
      - CosmosDB Account
      - CosmosDB SQL Database
      - CosmosDB SQL Container
      - Private Endpoint
      - Monitor Diagnostic Settings

    Output
      - azurerm_cosmosdb_account.adba1
      - azurerm_cosmosdb_sql_database.sql1
*/

// -
// - Data gathering
// -

# -
# - Load Resource Group
# - 
data "azurerm_resource_group" "rg" {
  name = var.cosmosdb_rg
}

# -
# - Load Subnets
# -
data "azurerm_subnet" "sub1" {
  for_each             = var.subnets
  name                 = each.value["name"]
  virtual_network_name = each.value["virtual_network_name"] 
  resource_group_name  = lookup(each.value, "resource_group_name", data.azurerm_resource_group.rg.name)  
}

# -
# - Load Log Analytic Workspace
# -
data "azurerm_log_analytics_workspace" "law1" {
  for_each            = var.log_analytics_workspace
  name                = each.value["name"]
  resource_group_name = each.value["resource_group_name"]
}

// -
// - Resources
// -

# -
# - CosmosDB Account
# -
resource "azurerm_cosmosdb_account" "cdba1" {
  for_each                              = var.cosmosdb_accounts
  name                                  = "${var.environment}-${each.value["team"]}-${each.value["name"]}-${each.value["instance"]}-cdb"                  
  location                              = lookup(each.value, "location", null) == null ? data.azurerm_resource_group.rg.location : each.value["location"] 
  resource_group_name                   = data.azurerm_resource_group.rg.name                               #(Required) The name of the resource group in which the CosmosDB Account is created. Changing this forces a new resource to be created.
  offer_type                            = each.value["offer_type"]                                          #(Required) Specifies the Offer Type to use for this CosmosDB Account - currently this can only be set to Standard.
  
  kind                                  = lookup(each.value, "kind", null)                                  #(Optional) Specifies the Kind of CosmosDB to create - possible values are GlobalDocumentDB and MongoDB. Defaults to GlobalDocumentDB. Changing this forces a new resource to be created.
  ip_range_filter                       = lookup(each.value, "ip_range_filter", null)                       #(Optional) CosmosDB Firewall Support: This value specifies the set of IP addresses or IP address ranges in CIDR form to be included as the allowed list of client IP's for a given database account. IP addresses/ranges must be comma separated and must not contain any spaces.  
  enable_free_tier                      = lookup(each.value, "enable_free_tier", null)                      #(Optional) Enable Free Tier pricing option for this Cosmos DB account. Defaults to false. Changing this forces a new resource to be create
  analytical_storage_enabled            = lookup(each.value, "analytical_storage_enabled", null)            #(Optional) Enable Analytical Storage option for this Cosmos DB account. Defaults to false. Changing this forces a new resource to be created.
  enable_automatic_failover             = lookup(each.value, "enable_automatic_failover", null)             #(Optional) Enable automatic fail over for this Cosmos DB account.
  public_network_access_enabled         = lookup(each.value, "public_network_access_enabled", null)         #(Optional) Whether or not public network access is allowed for this CosmosDB account. 
  is_virtual_network_filter_enabled     = lookup(each.value, "is_virtual_network_filter_enabled", null)     #(Optional) Enables virtual network filtering for this Cosmos DB account.
  key_vault_key_id                      = lookup(each.value, "key_vault_key_id ", null)                     #(Optional) A versionless Key Vault Key ID for CMK encryption. Changing this forces a new resource to be created.
  enable_multiple_write_locations       = lookup(each.value, "enable_multiple_write_locations", null)       #(Optional) Enable multi-master support for this Cosmos DB account.
  access_key_metadata_writes_enabled    = lookup(each.value, "access_key_metadata_writes_enabled", true)    #(Optional) Is write operations on metadata resources (databases, containers, throughput) via account keys enabled? Defaults to true.
  mongo_server_version                  = lookup(each.value, "mongo_server_version", null)                  #(Optional) The Server Version of a MongoDB account. Possible values are 4.0, 3.6, and 3.2. Changing this forces a new resource to be created.
  network_acl_bypass_for_azure_services = lookup(each.value, "network_acl_bypass_for_azure_services", false) #(Optional) If azure services can bypass ACLs. Defaults to false.
  network_acl_bypass_ids                = lookup(each.value, "network_acl_bypass_ids ", null)               #(Optional) The list of resource Ids for Network Acl Bypass for this Cosmos DB account.
  tags                                  = merge(data.azurerm_resource_group.rg.tags, lookup(each.value, "tags", null))


  consistency_policy {                                                                                      #(Required) Specifies a consistency_policy resource, used to define the consistency policy for this CosmosDB account.
    consistency_level       = lookup(each.value, "consistency_level", "BoundedStaleness")                   #(Required) The Consistency Level to use for this CosmosDB Account - can be either BoundedStaleness, Eventual, Session, Strong or ConsistentPrefix.
    max_interval_in_seconds = lookup(each.value, "max_interval_in_seconds", 5)                              #(Optional) When used with the Bounded Staleness consistency level, this value represents the time amount of staleness (in seconds) tolerated. Accepted range for this value is 5 - 86400 (1 day). Defaults to 5. Required when consistency_level is set to BoundedStaleness.
    max_staleness_prefix    = lookup(each.value, "max_staleness_prefix", 10)                                #(Optional) When used with the Bounded Staleness consistency level, this value represents the number of stale requests tolerated. Accepted range for this value is 10 – 2147483647. Defaults to 100. Required when consistency_level is set to BoundedStaleness.
  }

  dynamic "geo_location" {                                                                                  #(Optional) Additional geo_locations for failover
    for_each = lookup(each.value, "geo_location", var.null_array)                           
    content {
      location          = lookup(geo_location.value, "location", null)                                      #(Required) The name of the Azure region to host replicated data.  
      failover_priority = lookup(geo_location.value, "failover_priority", null)                             #(Required) The failover priority of the region. A failover priority of 0 indicates a write region. The maximum value for a failover priority = (total number of regions - 1). Failover priority values must be unique for each of the regions in which the database account exists. Changing this causes the location to be re-provisioned and cannot be changed for the location with failover priority 0.
      prefix            = lookup(geo_location.value, "prefix", null)                                        #(Optional) The string used to generate the document endpoints for this region. If not specified it defaults to ${cosmosdb_account.name}-${location}. Changing this causes the location to be deleted and re-provisioned and cannot be changed for the location with failover priority 0.      
      zone_redundant    = lookup(geo_location.value, "zone_redundant", null)                                #(Optional) Should zone redundancy be enabled for this region? Defaults to false.
    }
  }
  
  dynamic "capabilities" {                                                                                  #(Optional) Configures the capabilities to enable for this Cosmos DB account:
    for_each = lookup(each.value, "capabilities", var.null_array)
    content {
      name = lookup(capabilities.value, "name", null)                                                       #(Required) The capability to enable - Possible values are AllowSelfServeUpgradeToMongo36, DisableRateLimitingResponses, EnableAggregationPipeline, EnableCassandra, EnableGremlin, EnableMongo, EnableTable, EnableServerless, MongoDBv3.4 and mongoEnableDocLevelTTL.
    }
  }
  
  dynamic "virtual_network_rule" {                                                                          #(Optional) Specifies a virtual_network_rules resource, used to define which subnets are allowed to access this CosmosDB account.
    for_each = lookup(each.value, "virtual_network_rule", var.null_array)
    content {
      id                                   = lookup(virtual_network_rule.value, "subnet_key", null) == null ? null : lookup(data.azurerm_subnet.sub1, each.value["subnet_key"])["id"] #(Required) The ID of the virtual network subnet.
      ignore_missing_vnet_service_endpoint = lookup(virtual_network_rule.value, "ignore_missing_vnet_service_endpoint", null) #(Optional) If set to true, the specified subnet will be added as a virtual network rule even if its CosmosDB service endpoint is not active. Defaults to false.
    }
  }

  dynamic "backup" {
    for_each = lookup(each.value, "backup", var.null_array)
    content {
      type                = lookup(each.value, "type", null)                                                  #(Required) The type of the backup. Possible values are Continuous and Periodic. Defaults to Periodic.
      interval_in_minutes = lookup(each.value, "interval_in_minutes", null)                                   #(Optional) The interval in minutes between two backups. This is configurable only when type is Periodic. Possible values are between 60 and 1440.
      retention_in_hours  = lookup(each.value, "retention_in_hours", null)                                    #(Optional) The time in hours that each backup is retained. This is configurable only when type is Periodic. Possible values are between 8 and 720.    
    }
  }

  dynamic "cors_rule" {
    for_each = lookup(each.value, "cors_rule", var.null_array)
    content {
      allowed_headers    = lookup(each.value, "allowed_headers", null)                                        #(Required) A list of headers that are allowed to be a part of the cross-origin request.
      allowed_methods    = lookup(each.value, "allowed_methods", null)                                        #(Required) A list of http headers that are allowed to be executed by the origin. Valid options are DELETE, GET, HEAD, MERGE, POST, OPTIONS, PUT or PATCH.
      allowed_origins    = lookup(each.value, "allowed_origins", null)                                        #(Required) A list of origin domains that will be allowed by CORS.
      exposed_headers    = lookup(each.value, "exposed_headers", null)                                        #(Required) A list of response headers that are exposed to CORS clients.
      max_age_in_seconds = lookup(each.value, "max_age_in_seconds", null)                                     #(Required) The number of seconds the client should cache a preflight response.    
    }
  }

  identity {
    type = lookup(each.value, "type", "SystemAssigned")                                                     #(Required) Specifies the type of Managed Service Identity that should be configured on this Cosmos Account. Possible value is only SystemAssigned.
  }
  
}

# -
# - CosmosDB SQL Database
# -
resource "azurerm_cosmosdb_sql_database" "sql1" {
  depends_on          = [azurerm_cosmosdb_account.cdba1]  
  for_each            = var.cosmosdb_sql_databases
  name                = "${var.environment}-${each.value["team"]}-${each.value["name"]}-${each.value["instance"]}-sql" 
  resource_group_name = data.azurerm_resource_group.rg.name                                                 #(Required) The name of the resource group in which the CosmosDB SQL Database is created. Changing this forces a new resource to be created.
  account_name        = lookup(azurerm_cosmosdb_account.cdba1, each.value["cosmosdb_account_key"])["name"]  #(Required) The name of the Cosmos DB SQL Database to create the table within. Changing this forces a new resource to be crea
  
  throughput          = lookup(each.value, "throuput", null)                                                #(Optional) The throughput of SQL database (RU/s). Must be set in increments of 100. The minimum value is 400. This must be set upon database creation otherwise it cannot be updated without a manual terraform destroy-apply. Do not set when azurerm_cosmosdb_account is configured with EnableServerless capability.

  autoscale_settings {
    max_throughput    = lookup(each.value, "max_throughput", null)                                          #(Optional) The maximum throughput of the SQL database (RU/s). Must be between 4,000 and 1,000,000. Must be set in increments of 1,000. Conflicts with throughput.
  }
}

# -
# - CosmosDB SQL Container
# -
resource "azurerm_cosmosdb_sql_container" "sqlc1" {
  depends_on             = [azurerm_cosmosdb_account.cdba1]  
  for_each               = var.cosmosdb_sql_containers
  name                   = each.value["name"]                                          
  resource_group_name    = data.azurerm_resource_group.rg.name                         
  account_name           = lookup(azurerm_cosmosdb_account.cdba1, each.value["cosmosdb_account_key"])["name"]      #(Required) The name of the Cosmos DB Account to create the container within. Changing this forces a new resource to be created.
  database_name          = lookup(azurerm_cosmosdb_sql_database.sql1, each.value["cosmosdb_database_key"])["name"] #(Required) The name of the Cosmos DB SQL Database to create the container within. Changing this forces a new resource to be created.
  partition_key_path     = each.value["partition_key_path"]                                                 #(Required) Define a partition key. Changing this forces a new resource to be create
  
  partition_key_version  = lookup(each.value, "partition_key_version", null)                                #(Optional) Define a partition key version. Changing this forces a new resource to be created. Possible values are 1and 2. This should be set to 2 in order to use large partition keys.
  throughput             = lookup(each.value, "throughput", null)                                           #(Optional) The throughput of SQL container (RU/s). Must be set in increments of 100. The minimum value is 400. This must be set upon container creation otherwise it cannot be updated without a manual terraform destroy-apply.
  default_ttl            = lookup(each.value, "default_ttl", null)                                          #(Optional) The default time to live of SQL container. If missing, items are not expired automatically. If present and the value is set to -1, it is equal to infinity, and items don’t expire by default. If present and the value is set to some number n – items will expire n seconds after their last modified time.
  analytical_storage_ttl = lookup(each.value, "analytical_storage_ttl", null)                               #(Optional) The default time to live of Analytical Storage for this SQL container. If present and the value is set to -1, it is equal to infinity, and items don’t expire by default. If present and the value is set to some number n – items will expire n seconds after their last modified time.
  
  dynamic "unique_key" {                                                                                    #(Optional) One or more unique_key blocks as defined below. Changing this forces a new resource to be created.
    for_each = lookup(each.value, "unique_key", var.null_array)
    content {
      paths = unique_key.value["paths"]                                                                     #(Required) A list of paths to use for this unique key.      
    }
  }

  autoscale_settings {                                                                                      #(Optional) An autoscale_settings block as defined below. This must be set upon database creation otherwise it cannot be updated without a manual terraform destroy-apply. Requires partition_key_path to be set.
    max_throughput = lookup(each.value, "max_throughput", null)                                             #(Optional) The maximum throughput of the SQL container (RU/s). Must be between 4,000 and 1,000,000. Must be set in increments of 1,000. Conflicts with throughput.      
  }

  dynamic "indexing_policy" {                                                                               #(Optional) An indexing_policy block as defined below.
    for_each = lookup(each.value, "indexing_policy", var.null_array)                
    content {               
      indexing_mode   = lookup(indexing_policy.value, "indexing_mode", null)                                #(Optional) Indicates the indexing mode. Possible values include: Consistent and None. Defaults to Consistent.

      dynamic "included_path" {                                                                             #(Optional) One or more included_path blocks as defined below. Either included_path or excluded_path must contain the path 
        for_each = lookup(indexing_policy.value, "included_path", var.null_array)               
        content {               
          path   = lookup(included_path.value, "path", null)                                                #Path for which the indexing behaviour applies to.
        }               
      }               

      dynamic "excluded_path" {                                                                             #(Optional) One or more excluded_path blocks as defined below. Either included_path or excluded_path must contain the path 
        for_each = lookup(indexing_policy.value, "exculded_path", var.null_array)               
        content {               
          path   = lookup(excluded_path.value, "path", null)                                                #Path for which the indexing behaviour applies to.
        }               
      }

      dynamic "composite_index" {                                                                           #(Optional) One or more composite_index blocks as defined below.      
        for_each = lookup(indexing_policy.value, "composite_index", var.null_array)
        content {
          dynamic "index" {                                                                                 #One or more index blocks as defined below.          
            for_each = lookcup(composite_index.value, "index", var.null_array)
            content {
              path  = lookup(index.value, "path", null)                                                     #Path for which the indexing behaviour applies to.
              order = lookup(index.value, "order", null)                                                    #Order of the index. Possible values are Ascending or Descending.              
            }
          }
        }
      }

      dynamic "spatial_index" {
        for_each = lookup(indexing_policy.value, "spatial_index", var.null_array)
        content {
          path = lookup(spatial_index.value, "path", null)                                                  #(Required) Path for which the indexing behaviour applies to. According to the service design, all spatial types including LineString, MultiPolygon, Point, and Polygon will be applied to the path.
        }
      }
    }
  }

  dynamic "conflict_resolution_policy" {                                                                    #(Optional) A conflict_resolution_policy blocks as defined below.
    for_each = lookup(each.value, "conflict_resolution_policy", var.null_array)
    content {
      mode                          = lookup(each.value, "mode", null)                                      #(Required) Indicates the conflict resolution mode. Possible values include: LastWriterWins, Custom.
      conflict_resolution_path      = lookup(each.value, "conflict_resolution_path", null)                  #(Optional) The conflict resolution path in the case of LastWriterWins mode.
      conflict_resolution_procedure = lookup(each.value, "conflict_resolution_procedure", null)             #(Optional) The procedure to resolve conflicts in the case of Custom mode.      
    }
  }
}

# -
# - Private Endpoint
# -
resource "azurerm_private_endpoint" "ape1" {
  depends_on          = [azurerm_cosmosdb_account.cdba1]
  for_each            = var.private_endpoints
  name                = "${var.environment}-${each.value["name"]}-${each.value["instance"]}-ape"
  resource_group_name = data.azurerm_resource_group.rg.name                                                                             
  location            = lookup(each.value, "location", null) == null ? data.azurerm_resource_group.rg.location : each.value["location"]
  subnet_id           = lookup(data.azurerm_subnet.sub1, each.value["subnet_key"])["id"]                    #(Required) The ID of the Subnet from which Private IP Addresses will be allocated for this Private Endpoint. Changing this forces a new resource to be created.
  tags                = merge(data.azurerm_resource_group.rg.tags, lookup(each.value, "tags", null))        #(Optional) A mapping of tags to assign to the resource.

  dynamic "private_dns_zone_group" {                                                                        #(Optional) A private_dns_zone_group block as defined below.
    for_each = lookup(each.value, "private_dns_zone_group", var.null_array)
    content {
      name                 = lookup(each.value, "private_dns_zone_name", null)                                #(Required) Specifies the Name of the Private DNS Zone Group. Changing this forces a new private_dns_zone_group resource to be created.
      private_dns_zone_ids = lookup(each.value, "private_dns_zone_ids", null)                                 #(Required) Specifies the list of Private DNS Zones to include within the private_dns_zone_group.      
    }
  }
  
  private_service_connection {                                                                              #(Required) A private_service_connection block as defined below.
    name                              = lookup(each.value, "name", null)                                    #(Required) Specifies the Name of the Private Service Connection. Changing this forces a new resource to be created.
    is_manual_connection              = lookup(each.value, "is_manual_connection", null)                    #(Required) Does the Private Endpoint require Manual Approval from the remote resource owner? Changing this forces a new resource to be created.
    private_connection_resource_id    = lookup(each.value, "resource_key", null) == null ? null : lookup(azurerm_cosmosdb_account.cdba1, each.value["resource_key"])["id"] #(Optional) The ID of the Private Link Enabled Remote Resource which this Private Endpoint should be connected to. One of private_connection_resource_id or private_connection_resource_alias must be specified. Changing this forces a new resource to be created.
    private_connection_resource_alias = lookup(each.value, "private_connection_resource_alias", null)       #(Optional) The Service Alias of the Private Link Enabled Remote Resource which this Private Endpoint should be connected to. One of private_connection_resource_id or private_connection_resource_alias must be specified. Changing this forces a new resource to be created.
    subresource_names                 = lookup(each.value, "subresource_names", null)                       #(Optional) A list of subresource names which the Private Endpoint is able to connect to. subresource_names corresponds to group_id. Changing this forces a new resource to be created.
    request_message                   = lookup(each.value, "request_message", null)                         #(Optional) A message passed to the owner of the remote resource when the private endpoint attempts to establish the connection to the remote resource. The request message can be a maximum of 140 characters in length. Only valid if is_manual_connection is set to true.
  }
}

// -
// - Logging
// -

# -
# - Monitor Diagnostic Settings
# - 
resource "azurerm_monitor_diagnostic_setting" "mds1" {
  for_each                       = var.monitor_diagnostic_settings
  name                           = "mds-${each.value["name"]}-${var.environment}"                           #(Required) Specifies the name of the Diagnostic Setting. Changing this forces a new resource to be created.
  target_resource_id             = lookup(azurerm_cosmosdb_account.cdba1, each.value["resource_key"])["id"] #(Required) The ID of an existing Resource on which to configure Diagnostic Settings. Changing this forces a new resource to be created.
  
  eventhub_name                  = lookup(each.value, "eventhub_name", null)                                #(Optional) Specifies the name of the Event Hub where Diagnostics Data should be sent. Changing this forces a new resource to be created.  
  eventhub_authorization_rule_id = lookup(each.value, "eventhub_authorization_rule_id", null)               #(Optional) Specifies the ID of an Event Hub Namespace Authorization Rule used to send Diagnostics Data. Changing this forces a new resource to be created.    
  log_analytics_workspace_id     = lookup(each.value, "log_analytics_workspace_key", null) == null ? null: lookup(data.azurerm_log_analytics_workspace.law1, each.value["log_analytics_workspace_key"])["id"] #(Optional) Specifies the ID of a Log Analytics Workspace where Diagnostics Data should be sent.
  log_analytics_destination_type = lookup(each.value, "", null)                                             #(Optional) When set to 'Dedicated' logs sent to a Log Analytics workspace will go into resource specific tables, instead of the legacy AzureDiagnostics table.
  storage_account_id             = lookup(each.value, "storage_account_id", null)                           #(Optional) The ID of the Storage Account where logs should be sent. Changing this forces a new resource to be created    

  dynamic "log" {                                                                                           #(Optional) One or more log blocks as defined below.
    for_each = lookup(each.value, "log", [])    
    content {   
      category = log.value["category"]                                                                      #(Required) The name of a Diagnostic Log Category for this Resource.
      enabled  = lookup(log.value, "enabled", null)                                                         #(Optional) Is this Diagnostic Log enabled? Defaults to true.    

      retention_policy {                                                                                    #(Optional) A retention_policy block as defined below.
        enabled = log.value["retention_policy_enabled"]                                                     #(Required) Is this Retention Policy enabled?
        days    = lookup(log.value, "retention_policy_days", null)                                          #(Optional) The number of days for which this Retention Policy should apply.        
      }         
    }
  }

  dynamic "metric" {                                                                                        #(Optional) One or more metric blocks as defined below.
    for_each = lookup(each.value, "metric", [])
    content {
      category = metric.value["category"]                                                                   #(Required) The name of a Diagnostic Metric Category for this Resource.
      enabled = lookup(metric.value, "enabled", null)                                                       #(Optional) Is this Diagnostic Metric enabled? Defaults to true.      
        
      retention_policy {                                                                                    #(Optional) A retention_policy block as defined below.
        enabled = metric.value["retention_policy_enabled"]                                                  #(Required) Is this Retention Policy enabled?
        days    = lookup(metric.value, "retention_policy_days", null)                                       #(Optional) The number of days for which this Retention Policy should apply.        
      }     
    }
  }
}