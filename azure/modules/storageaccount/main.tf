# -
# - Data gathering
# -
data "azurerm_resource_group" "rg" {
  name = var.storage_account_rg
}

# -
# - Storage Accounts
# -

resource "azurerm_storage_account" "sa1" {
  for_each                  = var.storage_accounts
  name                      = "${each.value["name"]}"                                #(Required)(Unique) Specifies the name of the storage account. Changing this forces a new resource to be created. This must be unique across the entire Azure service, not just within the resource group.
  resource_group_name       = data.azurerm_resource_group.rg.name                    #(Required) The name of the resource group in which to create the storage account. Changing this forces a new resource to be created.
  location                  = var.storage_account_location                           #(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
  account_kind              = lookup(each.value, "account_kind", null)               #(Optional) Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2. Changing this forces a new resource to be created. Defaults to StorageV2.  
  account_tier              = each.value["account_tier"]                             #(Required) Defines the Tier to use for this storage account. Valid options are Standard and Premium. For BlockBlobStorage and FileStorage accounts only Premium is valid. Changing this forces a new resource to be created.
  account_replication_type  = each.value["account_replication_type"]                 #(Required) Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS.
  access_tier               = lookup(each.value, "access_tier", null)                #(Optional) Defines the access tier for BlobStorage, FileStorage and StorageV2 accounts. Valid options are Hot and Cool, defaults to Hot.
  enable_https_traffic_only = lookup(each.value, "enable_https_traffic_only", null)  #(Optional) Boolean flag which forces HTTPS if enabled, see here for more information. Defaults to true.
  min_tls_version           = lookup(each.value, "min_tls_version", null)            #(Optional) The minimum supported TLS version for the storage account. Possible values are TLS1_0, TLS1_1, and TLS1_2. Defaults to TLS1_0 for new storage accounts.
  allow_blob_public_access  = lookup(each.value, "allow_blob_public_access", null)   #Allow or disallow public access to all blobs or containers in the storage account. Defaults to false.
  is_hns_enabled            = lookup(each.value, "is_hns_enabled", null)             #(Optional) Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2 (see here for more information). Changing this forces a new resource to be created.
  nfsv3_enabled             = lookup(each.value, "nfsv3_enabled", null)              #(Optional) Is NFSv3 protocol enabled? Changing this forces a new resource to be created. Defaults to false.
  
  dynamic "custom_domain" {                                                          #(Optional) A custom_domain block as documented below.
    for_each = lookup(each.value, "custom_domain", [])
    content {
      name          = custom.domain.value["name"]                                    #(Required) The Custom Domain Name to use for the Storage Account, which will be validated by Azure.
      use_subdomain = lookup(custom_domain.value, "use_subdomain", null)             #(Optional) Should the Custom Domain Name be validated by using indirect CNAME validation?      
    }
  }
  
  dynamic "identity" {          #(Optional) A identity block as defined below.
    for_each = lookup(each.value, "identity", [])
    content {
      type         = identity.value["type"]                                          #(Required) Specifies the identity type of the Storage Account. Possible values are SystemAssigned, UserAssigned, SystemAssigned,UserAssigned (to enable both).  
      identity_ids = lookup(identity.value, "identity_ids", null)                    #(Optional) A list of IDs for User Assigned Managed Identity resources to be assigned.    
    }
  }
  
  dynamic "blob_properties" {                                                        #(Optional) A blob_properties block as defined below.
    for_each = lookup(each.value, "blob_properties", [])
    content {
      dynamic "cors_rule" {                                                          #(Optional) A cors_rule block as defined below.
        for_each = lookup(blob_properties.value, "cors_rule", [])
        content {
          allowed_headers    = cors_rule.value["allowed_headers"]                    #(Required) A list of headers that are allowed to be a part of the cross-origin request.
          allowed_methods    = cors_rule.value["allowed_methods"]                    #(Required) A list of http headers that are allowed to be executed by the origin. Valid options are DELETE, GET, HEAD, MERGE, POST, OPTIONS, PUT or PATCH.
          allowed_origins    = cors_rule.value["allowed_origins"]                    #(Required) A list of origin domains that will be allowed by CORS.
          exposed_headers    = cors_rule.value["exposed_headers"]                    #(Required) A list of response headers that are exposed to CORS clients.
          max_age_in_seconds = cors_rule.value["max_age_in_seconds"]                 #(Required) The number of seconds the client should cache a preflight response.          
        }
      }
      
      dynamic "delete_retention_policy" {                                            #(Optional) A delete_retention_policy block as defined below.
        for_each = lookup(blob_properties, "delete_retention_policy")
        content {
          days = lookup(delete_retention_policy.value, "days", null)                 #(Optional) Specifies the number of days that the blob should be retained, between 1 and 365 days. Defaults to 7.          
        }
      }
      
      versioning_enabled       = lookup(blob_properties.value, "versioning_enabled", null)       #(Optional) Is versioning enabled? Default to false.
      change_feed_enabled      = lookup(blob_properties.value, "change_feed_enabled", null)      #(Optional) Is the blob service properties for change feed events enabled? Default to false.
      default_service_version  = lookup(blob_properties.value, "default_service_version", null)  #(Optional) The API Version which should be used by default for requests to the Data Plane API if an incoming request doesn't specify an API Version. Defaults to 2020-06-12.
      last_access_time_enabled = lookup(blob_properties.value, "last_access_time_enabled", null) #(Optional) Is the last access time based tracking enabled? Default to false.
      
      dynamic "container_delete_retention_policy" {                                   #(Optional) A container_delete_retention_policy block as defined below.
        for_each = lookup(blob_properties, "container_delete_retention_policy")
        content {
          days = lookup(container_delete_retention_policy.value, "days", null)        #(Optional) Specifies the number of days that the container should be retained, between 1 and 365 days. Defaults to 7.          
        }      
      }
    }
  }

  dynamic "queue_properties" {  #(Optional) A queue_properties block as defined below.
    for_each = lookup(each.value, "queue_properties", [])
    content {
      dynamic "cors_rule" {                                                          #(Optional) A cors_rule block as defined below.
        for_each = lookup(queue_properties.value, "cors_rule", [])
        content {
          allowed_headers    = cors_rule.value["allowed_headers"]                    #(Required) A list of headers that are allowed to be a part of the cross-origin request.
          allowed_methods    = cors_rule.value["allowed_methods"]                    #(Required) A list of http headers that are allowed to be executed by the origin. Valid options are DELETE, GET, HEAD, MERGE, POST, OPTIONS, PUT or PATCH.
          allowed_origins    = cors_rule.value["allowed_origins"]                    #(Required) A list of origin domains that will be allowed by CORS.
          exposed_headers    = cors_rule.value["exposed_headers"]                    #(Required) A list of response headers that are exposed to CORS clients.
          max_age_in_seconds = cors_rule.value["max_age_in_seconds"]                 #(Required) The number of seconds the client should cache a preflight response.          
        }
      }

      dynamic "logging" {                                                            #(Optional) A logging block as defined below.
        for_each = lookup(queue_properties.value, "logging", [])
        content {
          delete                = logging.value["delete"]                            #(Required) Indicates whether all delete requests should be logged. Changing this forces a new resource.
          read                  = logging.value["read"]                              #(Required) Indicates whether all read requests should be logged. Changing this forces a new resource.
          version               = logging.value["version"]                           #(Required) The version of storage analytics to configure. Changing this forces a new resource.
          write                 = logging.value["write"]                             #(Required) Indicates whether all write requests should be logged. Changing this forces a new resource.
          retention_policy_days = logging.value["retention_policy_days"]             #(Optional) Specifies the number of days that logs will be retained. Changing this forces a new resource.          
        }
      }

      dynamic "minute_metrics" {                                                     #(Optional) A minute_metrics block as defined below.
        for_each = lookup(queue_properties.value, "minute_metrics", [])
        content {
          enabled               = minute_metrics.value["enabled"]                    #(Required) Indicates whether minute metrics are enabled for the Queue service. Changing this forces a new resource.
          version               = minute_metrics.value["version"]                    #(Required) The version of storage analytics to configure. Changing this forces a new resource.
          include_apis          = lookup(minute_metrics.value, "include_apis", null) #(Optional) Indicates whether metrics should generate summary statistics for called API operations.
          retention_policy_days = lookup(minute_metrics.value, "retention_policy_days", null) #(Optional) Specifies the number of days that logs will be retained. Changing this forces a new resource.        
        }      
      }
      
      dynamic "hour_metrics" {                                                       #(Optional) A hour_metrics block as defined below.      
        for_each = lookup(queue_properties.value, "hour_metrics", [])
        content {      
          enabled               = hour_metrics.value["enabled"]                      #(Required) Indicates whether hour metrics are enabled for the Queue service. Changing this forces a new resource.
          version               = hour_metrics.value["version"]                      #(Required) The version of storage analytics to configure. Changing this forces a new resource.
          include_apis          = lookup(hour_metrics.value, "include_apis", null)   #(Optional) Indicates whether metrics should generate summary statistics for called API operations.
          retention_policy_days = lookup(hour_metrics.value, "retention_policy_days", null) #(Optional) Specifies the number of days that logs will be retained. Changing this forces a new resource.        
        }
      }
    }
  }
  
  dynamic "static_website" {                                                         #(Optional) A static_website block as defined below.
    for_each = lookup(each.value, "static_website", [])
    content {  
      index_document     = lookup(static_website.value, "index_document", null)      #(Optional) The webpage that Azure Storage serves for requests to the root of a website or any subfolder. For example, index.html. The value is case-sensitive.
      error_404_document = lookup(static_website.value, "error_404_document", null)  #(Optional) The absolute path to a custom webpage that should be used when a request is made which does not correspond to an existing file.      
    }
  }

  dynamic "network_rules" {     #(Optional) A network_rules block as documented below.
    for_each = lookup(each.value, "network_rules", [])
    content { 
      default_action             = network_rules.value["default_action"]             #(Required) Specifies the default action of allow or deny when no other rules match. Valid options are Deny or Allow.
      bypass                     = lookup(network_rules.value, "bypass", null)       #(Optional) Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of Logging, Metrics, AzureServices, or None.
      ip_rules                   = lookup(network_rules.value, "ip_rules", null)     #(Optional) List of public IP or IP ranges in CIDR Format. Only IPV4 addresses are allowed. Private IP address ranges (as defined in RFC 1918) are not allowed.
      virtual_network_subnet_ids = lookup(network_rules.value, "virtual_network_subnet_ids", null) #(Optional) A list of resource ids for subnets.
      
      dynamic "private_link_access" {                                                #(Optional) One or More private_link_access block as defined below.      
        for_each = lookup(network_rules.value, "private_link_access", [])
        content { 
          endpoint_resource_id = private_link_access.value["endpoint_resource_id"]   #(Required) The resource id of the resource access rule to be granted access.
          endpoint_tenant_id   = lookup(private_link_access.value, "endpoint_tenant_id", null) #(Optional) The tenant id of the resource of the resource access rule to be granted access. Defaults to the current tenant id.
        }      
      }
    }  
  }
  
  large_file_share_enabled  = lookup(each.value, "large_file_share_enabled", null)  #(Optional) Is Large File Share Enabled?
  
  dynamic "azure_files_authentication" {                                            #(Optional) A azure_files_authentication block as defined below.
    for_each = lookup(each.value, "azure_files_authentication", [])
    content {  
      directory_type = azure_files_authentication.value["directory_type"]           #(Required) Specifies the directory service used. Possible values are AADDS and AD.

      dynamic "active_directory" {                                                  #(Optional) A active_directory block as defined below. Required when directory_type is AD.
        for_each = lookup(azure_files_authentication.value, "active_directory", [])
        content {
          storage_sid         = active_directory.value["storage_sid"]               #(Required) Specifies the security identifier (SID) for Azure Storage.
          domain_name         = active_directory.value["domain_name"]               #(Required) Specifies the primary domain that the AD DNS server is authoritative for.
          domain_sid          = active_directory.value["domain_sid"]                #(Required) Specifies the security identifier (SID).
          domain_guid         = active_directory.value["domain_guid"]               #(Required) Specifies the domain GUID.
          forest_name         = active_directory.value["forest_name"]               #(Required) Specifies the Active Directory forest.
          netbios_domain_name = active_directory.value["netbios_domain_name"]       #(Required) Specifies the NetBIOS domain name.          
        }
      }
    }
  }

  dynamic "routing" {           #(Optional) A routing block as defined below.
    for_each = lookup(each.value, "routing", [])
    content {  
      publish_internet_endpoints  = lookup(routing.value, "publish_internet_endpoints", null)  #(Optional) Should internet routing storage endpoints be published? Defaults to false.
      publish_microsoft_endpoints = lookup(routing.value, "publish_microsoft_endpoints", null) #(Optional) Should microsoft routing storage endpoints be published? Defaults to false.
      choice                      = lookup(routing.value, "choice", null)                      #(Optional) Specifies the kind of network routing opted by the user. Possible values are InternetRouting and MicrosoftRouting. Defaults to MicrosoftRouting.    
    }  
  }

  tags = data.azurerm_resource_group.rg.tags 
}