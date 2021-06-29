# -
# - Data gathering
# -
data "azurerm_resource_group" "rg" {
  name = var.redis_cache_rg
}

# -
# - Redis Cache
# -

resource "azurerm_redis_cache" "redis1" {
  for_each                      = var.redis_cache
  name                          = "redis-${each.value["name"]}-${each.value["priority"]}-${var.environment}" #(Required) The name of the Redis instance. Changing this forces a new resource to be created.
  resource_group_name           = data.azurerm_resource_group.rg.name                                        #(Required) The name of the resource group in which to create the Redis instance.
  location                      = var.redis_cache_location                                                   #(Required) The location of the resource group.
  capacity                      = each.value["capacity"]                                                     #(Required) The size of the Redis cache to deploy. Valid values for a SKU family of C (Basic/Standard) are 0, 1, 2, 3, 4, 5, 6, and for P (Premium) family are 1, 2, 3, 4.
  family                        = each.value["family"]                                                       #(Required) The SKU family/pricing group to use. Valid values are C (for Basic/Standard SKU family) and P (for Premium)
  sku_name                      = each.value["sku_name"]                                                     #(Required) The SKU of Redis to use. Possible values are Basic, Standard and Premium
  enable_non_ssl_port           = lookup(each.value, "enable_non_ssl_port", null)                            #(Optional) Enable the non-SSL port (6379) - disabled by default.
  minimum_tls_version           = lookup(each.value, "minimum_tls_version", null)                            #(Optional) The minimum TLS version. Defaults to 1.0.

  dynamic "patch_schedule" {                                                                                 #(Optional) A list of patch_schedule blocks
    for_each = lookup(each.value, "patch_schedule", [])
    content {    
      day_of_week               = patch_schedule.value["day_of_week"]                                        #(Required) the Weekday name - possible values include Monday, Tuesday, Wednesday etc.
      start_hour_utc            = lookup(patch_schedule.value, "start_hour_utc", null)                       #(Optional) the Start Hour for maintenance in UTC - possible values range from 0 - 23.
    }
  }

  private_static_ip_address     = lookup(each.value, "private_static_ip_address", null)                      #(Optional) The Static IP Address to assign to the Redis Cache when hosted inside the Virtual Network. Changing this forces a new resource to be created.
  public_network_access_enabled = lookup(each.value, "public_network_access_enabled", null)                  #(Optional) Whether or not public network access is allowed for this Redis Cache. true means this resource could be accessed by both public and private endpoint. false means only private endpoint access is allowed. Defaults to true.
  
  dynamic "redis_configuration" {                                                                            #(Optional) A redis_configuration as defined below - with some limitations by SKU - defaults/details are shown below.                        
    for_each = lookup(each.value, "redis_configuration", [])
    content {
      aof_backup_enabled              = lookup(each.value, "aof_backup_enabled", null)                       #(Optional) Enable or disable AOF persistence for this Redis Cache.
      aof_storage_connection_string_0 = lookup(each.value, "aof_storage_connection_string_0", null)          #(Optional) First Storage Account connection string for AOF persistence.
      aof_storage_connection_string_1 = lookup(each.value, "aof_storage_connection_string_1", null)          #(Optional) Second Storage Account connection string for AOF persistence.
      enable_authentication           = lookup(each.value, "enable_authentication", null)                    #(Optional) If set to false, the Redis instance will be accessible without authentication. Defaults to true.   
      maxmemory_reserved              = lookup(each.value, "maxmemory_reserved", null)                       #(Optional) Value in megabytes reserved for non-cache usage e.g. failover. Defaults are shown below.
      maxmemory_delta                 = lookup(each.value, "maxmemory_delta", null)                          #(Optional) The max-memory delta for this Redis instance. Defaults are shown below.
      maxmemory_policy                = lookup(each.value, "maxmemory_policy", null)                         #(Optional) How Redis will select what to remove when maxmemory is reached. Defaults are shown below.
      maxfragmentationmemory_reserved = lookup(each.value, "maxfragmentationmemory_reserved", null)          #(Optional) Value in megabytes reserved to accommodate for memory fragmentation. Defaults are shown below.
      rdb_backup_enabled              = lookup(each.value, "rdb_backup_enabled", null)                       #(Optional) Is Backup Enabled? Only supported on Premium SKU's.
      rdb_backup_frequency            = lookup(each.value, "rdb_backup_frequency", null)                     #(Optional) The Backup Frequency in Minutes. Only supported on Premium SKU's. Possible values are: 15, 30, 60, 360, 720 and 1440.
      rdb_backup_max_snapshot_count   = lookup(each.value, "rdb_backup_max_snapshot_count", null)            #(Optional) The maximum number of snapshots to create as a backup. Only supported for Premium SKU's.
      rdb_storage_connection_string   = lookup(each.value, "rdb_storage_connection_string", null)            #(Optional) The Connection String to the Storage Account. Only supported for Premium SKU's
      notify_keyspace_events          = lookup(each.value, "notify_keyspace_events", null)                   #(Optional) Keyspace notifications allows clients to subscribe to Pub/Sub channels in order to receive events affecting the Redis data set in some way.  
    }
  }

  replicas_per_master           = lookup(each.value, "replicas_per_master", null)                            #(Optional) Amount of replicas to create per master for this Redis Cache.
  shard_count                   = lookup(each.value, "shard_count", null)                                    #(Optional) Only available when using the Premium SKU The number of Shards to create on the Redis Cluster.
  subnet_id                     = lookup(each.value, "subnet_id", null)                                      #(Optional) Only available when using the Premium SKU The ID of the Subnet within which the Redis Cache should be deployed. This Subnet must only contain Azure Cache for Redis instances without any other type of resources. Changing this forces a new resource to be created.
  zones                         = lookup(each.value, "zones", null)                                          #(Optional) A list of a one or more Availability Zones, where the Redis Cache should be allocated.

  tags = data.azurerm_resource_group.rg.tags
}  

resource "azurerm_redis_firewall_rule" "redisfw1" {
  for_each            = var.redis_cache_firewall_rules
  name                = "redisrule${each.value["name"]}${var.environment}"                                  #(Required) The name of the Firewall Rule. Changing this forces a new resource to be created.
  resource_group_name = data.azurerm_resource_group.rg.name                                                 #(Required) The name of the resource group in which this Redis Cache exists.
  redis_cache_name    = lookup(azurerm_redis_cache.redis1, each.value["redis_cache_key"])["name"]           #(Required) The name of the Redis Cache. Changing this forces a new resource to be created.
  start_ip            = each.value["start_ip"]                                                              #(Required) The lowest IP address included in the range
  end_ip              = each.value["end_ip"]                                                                #(Required) The highest IP address included in the range.
} 