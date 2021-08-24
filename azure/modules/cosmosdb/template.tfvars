/**********************************************

    Argument Template for CosmosDB Module
    
    ** Existing Resource Group, Subnets and
       Log Analytics Workspace

***********************************************/

// -
// - General
// -
environment = "example"

// -
// - Load Existing Resources
// -

# -
# - Load Existing Resource Group
# -
cosmosdb_rg = "EXAMPLE-COSMOSDB-RG"

# -
# - Load Existing Subnets
# -
existing_subnets = {
  cosmosdb-subnet = {
    name                 = "CosmosDB-Subnet"
    virtual_network_name = "example-cosmosdb-01-vnet"
    resource_group_name  = "EXAMPLE-NETWORK-RG"     
  }
}

# -
# - Load Existing Log Analytics Workspace
# -
log_analytics_workspaces = {
  cosmosdb-law = {
    name                = "example-cosmosdb-01-law"
    resource_group_name = "EXAMPLE-COSMOSDB-RG"
  }
}

// -
// - Main resources
// -

# -
# - CosmosDB Accounts
# -
cosmosdb_accounts = {
  cosmosdb-account-1 = {
    # Required Arguments
    team                                  = "apps"
    name                                  = "cosmosdb"                                          #(Required) Core name of the resource [ENVIRONMENT-NAME-INSTANCE-cbda]
    instance                              = "01"                                                #(Required) This can be any String to denote this resource               
    offer_type                            = "Standard"                                          #(Required) Specifies the Offer Type to use for this CosmosDB Account - currently this can only be set to Standard.
    # consistency_policy
    consistency_level                     = "BoundedStaleness"                                  #(Required) The Consistency Level to use for this CosmosDB Account - can be either BoundedStaleness, Eventual, Session, Strong or ConsistentPrefix.
    # max_interval_in_seconds               = 5                                                 #(Optional) When used with the Bounded Staleness consistency level, this value represents the time amount of staleness (in seconds) tolerated. Accepted range for this value is 5 - 86400 (1 day). Defaults to 5. Required when consistency_level is set to BoundedStaleness.
    # max_staleness_prefix                  = 100                                               #(Optional) When used with the Bounded Staleness consistency level, this value represents the number of stale requests tolerated. Accepted range for this value is 10 – 2147483647. Defaults to 100. Required when consistency_level is set to BoundedStaleness.
    
    # Optional Arguments
    /*
    location                              = "East US"                                           #(Optional) Specify the Azure Region.  The Resource Group Location is used by default.
    kind                                  = "GlobalDocumentDB"                                  #(Optional) Specifies the Kind of CosmosDB to create - possible values are GlobalDocumentDB and MongoDB. Defaults to GlobalDocumentDB. Changing this forces a new resource to be created.
    ip_range_filter                       = ["1.1.1.1/32", "10.10.10.0/24"]                     #(Optional) CosmosDB Firewall Support: This value specifies the set of IP addresses or IP address ranges in CIDR form to be included as the allowed list of client IP's for a given database account. IP addresses/ranges must be comma separated and must not contain any spaces.  
    enable_free_tier                      = false                                               #(Optional) Enable Free Tier pricing option for this Cosmos DB account. Defaults to false. Changing this forces a new resource to be create
    analytical_storage_enabled            = false                                               #(Optional) Enable Analytical Storage option for this Cosmos DB account. Defaults to false. Changing this forces a new resource to be created.
    enable_automatic_failover             = true                                                #(Optional) Enable automatic fail over for this Cosmos DB account.
    public_network_access_enabled         = false                                               #(Optional) Whether or not public network access is allowed for this CosmosDB account. 
    is_virtual_network_filter_enabled     = false                                               #(Optional) Enables virtual network filtering for this Cosmos DB account.
    key_vault_key_id                      = "https://example.vault.azure.net/keys/cosmosdb_key" #(Optional) A versionless Key Vault Key ID for CMK encryption. Changing this forces a new resource to be created.
    enable_multiple_write_locations       = false                                               #(Optional) Enable multi-master support for this Cosmos DB account.
    access_key_metadata_writes_enabled    = true                                                #(Optional) Is write operations on metadata resources (databases, containers, throughput) via account keys enabled? Defaults to true.
    mongo_server_version                  = ""                                                  #(Optional) The Server Version of a MongoDB account. Possible values are 4.0, 3.6, and 3.2. Changing this forces a new resource to be created.
    network_acl_bypass_for_azure_services = false                                               #(Optional) If azure services can bypass ACLs. Defaults to false.
    network_acl_bypass_ids                = ["resource_id_1", "resource_id_2"]                  #(Optional) The list of resource Ids for Network Acl Bypass for this Cosmos DB account.
    tags                                  = {
                                              "application" = "example"
                                              "service"     = "cosmosdb_account"
                                            }

    virtual_network_rule = {                                                                    #(Optional) Specifies a virtual_network_rules resource, used to define which subnets are allowed to access this CosmosDB account.
      vnr1 = {
        subnet_key                           =  "cosmosdb-subnet"                               #(Required) The Key of the virtual network subnet loaded in the data gathering.
        ignore_missing_vnet_service_endpoint =  false                                           #(Optional) If set to true, the specified subnet will be added as a virtual network rule even if its CosmosDB service endpoint is not active. Defaults to false.
      }
    }

    backup = {
      backup1 = {  
        type                = "Periodic"                                                            #(Required) The type of the backup. Possible values are Continuous and Periodic. Defaults to Periodic.
        interval_in_minutes = 60                                                                    #(Optional) The interval in minutes between two backups. This is configurable only when type is Periodic. Possible values are between 60 and 1440.
        retention_in_hours  = 8                                                                     #(Optional) The time in hours that each backup is retained. This is configurable only when type is Periodic. Possible values are between 8 and 720.    
      }
    }

    cors_rules = {
      cors1 ={
        allowed_headers    = []                                                                     #(Required) A list of headers that are allowed to be a part of the cross-origin request.
        allowed_methods    = []                                                                     #(Required) A list of http headers that are allowed to be executed by the origin. Valid options are DELETE, GET, HEAD, MERGE, POST, OPTIONS, PUT or PATCH.
        allowed_origins    = []                                                                     #(Required) A list of origin domains that will be allowed by CORS.
        exposed_headers    = []                                                                     #(Required) A list of response headers that are exposed to CORS clients.
        max_age_in_seconds = 10                                                                     #(Required) The number of seconds the client should cache a preflight response.    
      }
    }

    # identity - (Optional)
    type = "SystemAssigned"                                                                     #(Required) Specifies the type of Managed Service Identity that should be configured on this Cosmos Account. Possible value is only SystemAssigned.

    geo_location = {                                                                            #(Optional) Additional geo_locations for failover
      location_eastus = {
        location          = "East US"                                                           #(Required) The name of the Azure region to host replicated data.  
        failover_priority = "0"                                                                 #(Required) The failover priority of the region. A failover priority of 0 indicates a write region. The maximum value for a failover priority = (total number of regions - 1). Failover priority values must be unique for each of the regions in which the database account exists. Changing this causes the location to be re-provisioned and cannot be changed for the location with failover priority 0.
        prefix            = "example-cosmosdb-01-eastus"                                        #(Optional) The string used to generate the document endpoints for this region. If not specified it defaults to ${cosmosdb_account.name}-${location}. Changing this causes the location to be deleted and re-provisioned and cannot be changed for the location with failover priority 0.        
        zone_redundant    = true                                                                #(Optional) Should zone redundancy be enabled for this region? Defaults to false.
      }
      location_westus = {
        location          = "West US"
        failover_priority = "1"
        prefix            = "example-cosmosdb-01-eastus"
        zone_redundant    = true
      }
    }    

    capabilities = {                                                                            #(Optional) Configures the capabilities to enable for this Cosmos DB account:
      capabilities_1 = {
        name = "EnableCassandra"                                                                #(Required) The capability to enable - Possible values are AllowSelfServeUpgradeToMongo36, DisableRateLimitingResponses, EnableAggregationPipeline, EnableCassandra, EnableGremlin, EnableMongo, EnableTable, EnableServerless, MongoDBv3.4 and mongoEnableDocLevelTTL.
      }
      capabilities_2 = {
        name = "DisableRateLimitingResponses"
      }
    }
    */
  }
  cosmosdb-account-2 = {
    # Required Arguments
    team                                  = "apps"
    name                                  = "cosmosdb"
    instance                              = "02"
    offer_type                            = "Standard"
    # consistency_policy
    consistency_level                     = "BoundedStaleness"
    max_interval_in_seconds               = 5
    max_staleness_prefix                  = 100
  }
}

# -
# - CosmosDB SQL Database
# -
cosmosdb_sql_databases = {
  sql-database-01 = {
    # Required
    team                 = "apps"
    name                 = "sql-database"       #(Required) Core name of the resource [ENVIRONMENT-NAME-INSTANCE-sql]
    instance             = "01"                 #(Required) This can be any String to denote this resource 
    cosmosdb_account_key = "cosmosdb-account-1" #(Required) The Key of the Cosmos DB account created in the module
  
    # Optional Arguments
    /*
    throughput           = 400                  #(Optional) The throughput of SQL database (RU/s). Must be set in increments of 100. The minimum value is 400. This must be set upon database creation otherwise it cannot be updated without a manual terraform destroy-apply. Do not set when azurerm_cosmosdb_account is configured with EnableServerless capability.
    max_throughput       = 4000                 #(Optional) The maximum throughput of the SQL database (RU/s). Must be between 4,000 and 1,000,000. Must be set in increments of 1,000. Conflicts with throughput.
    */
  }
  sql-database-02 = {  
    # Required
    team                 = "apps"
    name                 = "sql-database"
    instance             = "02"
    cosmosdb_account_key = "cosmosdb-account-2"
  }
}

# -
# - CosmosDB SQL Container
# -
cosmosdb_sql_containers ={
  container-01 = {
    # Required
    name                          = "Container1"                      #(Required) The name of the Container
    cosmosdb_account_key          = "cosmosdb-account-01"             #(Required) The Key of the Cosmos DB Account to create the container within. Changing this forces a new resource to be created.
    cosmosdb_database_key         = "sql-database-01"                 #(Required) The Key of the Cosmos DB SQL Database to create the container within. Changing this forces a new resource to be created.
    partition_key_path            = "/definition/id"                  #(Required) Define a partition key. Changing this forces a new resource to be create
  
    # Optional Arguments
    /*
    partition_key_version         = 1                                 #(Optional) Define a partition key version. Changing this forces a new resource to be created. Possible values are 1and 2. This should be set to 2 in order to use large partition keys.
    throughput                    = 400                               #(Optional) The throughput of SQL container (RU/s). Must be set in increments of 100. The minimum value is 400. This must be set upon container creation otherwise it cannot be updated without a manual terraform destroy-apply.
    default_ttl                   = ""                                #(Optional) The default time to live of SQL container. If missing, items are not expired automatically. If present and the value is set to -1, it is equal to infinity, and items don’t expire by default. If present and the value is set to some number n – items will expire n seconds after their last modified time.
    analytical_storage_ttl        = ""                                #(Optional) The default time to live of Analytical Storage for this SQL container. If present and the value is set to -1, it is equal to infinity, and items don’t expire by default. If present and the value is set to some number n – items will expire n seconds after their last modified time.
    
    # autoscale_settings - (Optional) An autoscale_settings block as defined below. This must be set upon database creation otherwise it cannot be updated without a manual terraform destroy-apply. Requires partition_key_path to be set.
    max_throughput                = 4000                              #(Optional) The maximum throughput of the SQL container (RU/s). Must be between 4,000 and 1,000,000. Must be set in increments of 1,000. Conflicts with throughput.      
    
    conflict_resolution_policy = {                                    #(Optional) A conflict_resolution_policy blocks as defined below.
      crp1 = {
        mode                          = ""                            #(Required) Indicates the conflict resolution mode. Possible values include: LastWriterWins, Custom.
        conflict_resolution_path      = ""                            #(Optional) The conflict resolution path in the case of LastWriterWins mode.
        conflict_resolution_procedure = ""                            #(Optional) The procedure to resolve conflicts in the case of Custom mode.      
      }
    }

    unique_key = {                                                    #(Optional) One or more unique_key blocks as defined below. Changing this forces a new resource to be created.
      unique-key-01 ={
        paths = ["/"]                                                 #(Required) A list of paths to use for this unique key.      
      }
    }

    indexing_policy = {                                               #(Optional) An indexing_policy block as defined below.
      indexing-policy-01 = {             
        indexing_mode   = "Consistent"                                #(Optional) Indicates the indexing mode. Possible values include: Consistent and None. Defaults to Consistent.

        included_path = {                                             #(Optional) One or more included_path blocks as defined below. Either included_path or excluded_path must contain the path 
          path-01 = {
            path = "/*"                                               #Path for which the indexing behaviour applies to.
          }               
        }               

        excluded_path = {                                             #(Optional) One or more excluded_path blocks as defined below. Either included_path or excluded_path must contain the path 
          path-01 = {                        
            path = "/*"                                               #Path for which the indexing behaviour applies to.
          }               
        }

        composite_index = {                                           #(Optional) One or more composite_index blocks as defined below.      
          composite-index-01 = {
            index = {
              index-01 = {                                            #One or more index blocks as defined below.          
                path  = "/*"                                          #Path for which the indexing behaviour applies to.
                order = "/*"                                          #Order of the index. Possible values are Ascending or Descending.              
              }
            }
          }
        }

        spatial_index = {
          spatial-index-01 ={
            path = "/*"                                               #(Required) Path for which the indexing behaviour applies to. According to the service design, all spatial types including LineString, MultiPolygon, Point, and Polygon will be applied to the path.
          }
        }
      }
    }
    */
  }
  container-02 = {
    # Required
    name                          = "Container2"
    cosmosdb_account_key          = "cosmosdb-account-01"
    cosmosdb_database_key         = "sql-database-01"
    partition_key_path            = "/definition/id"
}

# -
# - Private Endpoint
# -
private_endpoints = {
  cosmosdb-01-private-endpoint = {
    # Required Arguments
    name                              = "cosmosdb"                          #(Required) Core name of the resource [ENVIRONMENT-NAME-INSTANCE-cbda]
    instance                          = "01"                                #(Required) This can be any String to denote this resource               
    subnet_key                        =  "cosmosdb-subnet"                  #(Required) The Key of the virtual network subnet loaded in the data gathering.
    
    # private_service_connection - (Required) A private_service_connection block as defined below.
    name                              = "cosmosdb-01-psc"                   #(Required) Specifies the Name of the Private Service Connection. Changing this forces a new resource to be created.
    is_manual_connection              = false                               #(Required) Does the Private Endpoint require Manual Approval from the remote resource owner? Changing this forces a new resource to be created.
    resource_key                      = "cosmosdb-account-01"               #(Optional) The ID of the Private Link Enabled Remote Resource which this Private Endpoint should be connected to. One of private_connection_resource_id or private_connection_resource_alias must be specified. Changing this forces a new resource to be created.
    private_connection_resource_alias = ""                                  #(Optional) The Service Alias of the Private Link Enabled Remote Resource which this Private Endpoint should be connected to. One of private_connection_resource_id or private_connection_resource_alias must be specified. Changing this forces a new resource to be created.
    subresource_names                 = ["", ""]                            #(Optional) A list of subresource names which the Private Endpoint is able to connect to. subresource_names corresponds to group_id. Changing this forces a new resource to be created.
    request_message                   = "Allow Connection"                  #(Optional) A message passed to the owner of the remote resource when the private endpoint attempts to establish the connection to the remote resource. The request message can be a maximum of 140 characters in length. Only valid if is_manual_connection is set to true.

    # Optional Arguments
    /*
    location                          = "East US"                           #(Optional) Specify the Azure Region.  The Resource Group Location is used by default.
    tags                              = {
                                          "application" = "example"
                                          "service"     = "cosmosdb_private_endpoint"
                                        }

    private_dns_zone_group = {                                              #(Optional) A private_dns_zone_group block as defined below.
      pdzg1 = {
        name                              = ""                              #(Required) Specifies the Name of the Private DNS Zone Group. Changing this forces a new private_dns_zone_group resource to be created.
        private_dns_zone_ids              = ""                              #(Required) Specifies the list of Private DNS Zones to include within the private_dns_zone_group.      
      }
    }
    */
  }
}

// -
// - Logging
// -

# -
# - Monitor Diagnostic Settings
# -
monitor_diagnostic_settings = {
  cosmosdb-account-01-mds = {
    # Required
    name                           = "example-cosmosdb-01"    #(Required) Specifies the name of the Diagnostic Setting. Changing this forces a new resource to be created.
    resource_key                   = "cosmosdb-account-01"    #(Optional) The ID of the Private Link Enabled Remote Resource which this Private Endpoint should be connected to. One of private_connection_resource_id or private_connection_resource_alias must be specified. Changing this forces a new resource to be created.
    log_analytics_workspace_key    = "cosmosdb-law"           #(Required) Specifies the ID of a Log Analytics Workspace where Diagnostics Data should be sent.
  
    # Optional Arguments
    /*
    eventhub_name                  = ""                       #(Optional) Specifies the name of the Event Hub where Diagnostics Data should be sent. Changing this forces a new resource to be created.  
    eventhub_authorization_rule_id = ""                       #(Optional) Specifies the ID of an Event Hub Namespace Authorization Rule used to send Diagnostics Data. Changing this forces a new resource to be created.    
    log_analytics_destination_type = ""                       #(Optional) When set to 'Dedicated' logs sent to a Log Analytics workspace will go into resource specific tables, instead of the legacy AzureDiagnostics table.
    storage_account_id             = ""                       #(Optional) The ID of the Storage Account where logs should be sent. Changing this forces a new resource to be created    

    log = {                                                   #(Optional) One or more log blocks as defined below.
      log-01 = {   
        category = "AuditEvent"                               #(Required) The name of a Diagnostic Log Category for this Resource.
        enabled  = true                                       #(Optional) Is this Diagnostic Log enabled? Defaults to true.    

        # retention_policy - (Optional) A retention_policy block as defined below.
        retention_policy_enabled = true                       #(Required) Is this Retention Policy enabled?
        retention_policy_days    = 365                        #(Optional) The number of days for which this Retention Policy should apply.             
      }
    }

    metric = {                                                #(Optional) One or more log blocks as defined below.
      metric-01 = {   
        category = "AllMetrics"                               #(Required) The name of a Diagnostic Log Category for this Resource.
        enabled  = true                                       #(Optional) Is this Diagnostic Log enabled? Defaults to true.    

        # retention_policy - (Optional) A retention_policy block as defined below.
        retention_policy_enabled = true                       #(Required) Is this Retention Policy enabled?
        retention_policy_days    = 365                        #(Optional) The number of days for which this Retention Policy should apply.             
      }
    }
    */
  }
  cosmosdb-account-02-mds = {
    # Required
    name                           = "example-cosmosdb-02"    #(Required) Specifies the name of the Diagnostic Setting. Changing this forces a new resource to be created.
    resource_key                   = "cosmosdb-account-02"    #(Optional) The ID of the Private Link Enabled Remote Resource which this Private Endpoint should be connected to. One of private_connection_resource_id or private_connection_resource_alias must be specified. Changing this forces a new resource to be created.
    log_analytics_workspace_key    = "cosmosdb-law"           #(Required) Specifies the ID of a Log Analytics Workspace where Diagnostics Data should be sent.
  }
}