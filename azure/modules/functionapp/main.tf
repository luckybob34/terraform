# -
# - Data gathering
# -
data "azurerm_resource_group" "rg" {
  name = var.function_app_rg
}

data "azurerm_storage_account" "sa1" {
  for_each            = var.existing_storage_accounts
  name                = each.value["name"]
  resource_group_name = lookup(each.value, "resource_group_name", data.azurerm_resource_group.rg.name)
}
# -
# - App Service Plan
# -

resource "azurerm_app_service_plan" "asp1" {
  for_each                     = var.app_service_plans
  name                         = "${each.value["name"]}-${each.value["priority"]}-${var.environment}"
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = var.function_app_location
  kind                         = lookup(each.value, "kind", null)                               #(Optional) The kind of the App Service Plan to create. Possible values are Windows (also available as App), Linux, elastic (for Premium Consumption) and FunctionApp (for a Consumption Plan). Defaults to Windows. Changing this forces a new resource to be created.
  maximum_elastic_worker_count = lookup(each.value, "maximum_elastic_worker_count", null)       #The maximum number of total workers allowed for this ElasticScaleEnabled App Service Plan.

  sku {
    tier     = each.value["sku_tier"]                                                           #(Required) Specifies the plan's pricing tier.
    size     = each.value["sku_size"]                                                           #(Required) Specifies the plan's instance size.
    capacity = lookup(each.value, "sku_capacity", null)                                         #(Optional) Specifies the number of workers associated with this App Service Plan.
  }

  app_service_environment_id = null                                                             #(Optional) The ID of the App Service Environment where the App Service Plan should be located. Changing forces a new resource to be created./*
  /*
  #This forces a destroy when adding a new lb --> loadbalancer_id     = lookup(azurerm_lb.lb, each.value["lb_key"])["id"]
  depends_on      = [azurerm_lb.lb]
  loadbalancer_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.lb_resource_group_name}/providers/Microsoft.Network/loadBalancers/${var.lb_prefix}-${lookup(var.Lbs, each.value["lb_key"], "wrong_lb_key_in_LbRules")["suffix_name"]}-lb${lookup(var.Lbs, each.value["lb_key"], "wrong_lb_key_in_LbRules")["id"]}"
*/
  reserved         = lookup(each.value, "reserved", null)                                       #(Optional) Is this App Service Plan Reserved. Defaults to false.
  per_site_scaling = lookup(each.value, "per_site_scaling", null)                               #(Optional) Can Apps assigned to this App Service Plan be scaled independently? If set to false apps assigned to this plan will scale to all instances of the plan. Defaults to false.
  tags             = data.azurerm_resource_group.rg.tags

}
# -
# - Storage Accounts
# -

resource "azurerm_storage_account" "sa1" {
  for_each                 = var.storage_accounts
  name                     = "${each.value["name"]}"                        #(Required)(Unique) Specifies the name of the storage account. Changing this forces a new resource to be created. This must be unique across the entire Azure service, not just within the resource group.
  resource_group_name      = data.azurerm_resource_group.rg.name            #(Required) The name of the resource group in which to create the storage account. Changing this forces a new resource to be created.
  location                 = var.function_app_location                      #(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
  account_tier             = each.value["account_tier"]                     #(Required) Defines the Tier to use for this storage account. Valid options are Standard and Premium. For BlockBlobStorage and FileStorage accounts only Premium is valid. Changing this forces a new resource to be created.
  account_replication_type = each.value["account_replication_type"]         #(Required) Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS.
}


# -
# - Function Apps
# -
resource "azurerm_function_app" "apps1" {
  depends_on                 = [azurerm_storage_account.sa1]
  for_each                   = var.function_apps
  name                       = "func-${each.value["name"]}-${each.value["priority"]}-${var.environment}"                                                             #(Required) Specifies the name of the App Service. Changing this forces a new resource to be created.
  resource_group_name        = data.azurerm_resource_group.rg.name                                                                                                   #(Required) The name of the resource group in which to create the App Service.
  location                   = var.function_app_location                                                                                                             #(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
  app_service_plan_id        = lookup(azurerm_app_service_plan.asp1, each.value["app_service_plan_key"])["id"]                                                       #(Required) The ID of the App Service Plan within which to create this App Service.
  storage_account_name       = lookup(merge(azurerm_storage_account.sa1, data.azurerm_storage_account.sa1), each.value["storage_account_key"])["name"]               #(Required) The backend storage account name which will be used by this Function App (such as the dashboard, logs).
  storage_account_access_key = lookup(merge(azurerm_storage_account.sa1, data.azurerm_storage_account.sa1), each.value["storage_account_key"])["primary_access_key"] #(Required) The access key which will be used to access the backend storage account for the Function App.
  app_settings               = lookup(each.value, "app_settings", null)                                                                                              #(Optional) A key-value pair of App Settings.
  
  # -
  # - Authentication Settings for the App Service (Optional)
  # -
  auth_settings {
    enabled = lookup(each.value, "enabled", false)                                              #(Required) Is Authentication enabled?
    #active_directory {}
    additional_login_params        = lookup(each.value, "additional_login_params", null)        #(Optional) Login parameters to send to the OpenID Connect authorization endpoint when a user logs in. Each parameter must be in the form "key=value".
    allowed_external_redirect_urls = lookup(each.value, "allowed_external_redirect_urls", null) #(Optional) External URLs that can be redirected to as part of logging in or logging out of the app.
    default_provider               = lookup(each.value, "default_provider", null)               #(Optional) The default provider to use when multiple providers have been set up. Possible values are AzureActiveDirectory, Facebook, Google, MicrosoftAccount and Twitter. NOTE: When using multiple providers, the default provider must be set for settings like unauthenticated_client_action to work.
    #facebook {}
    #google {}
    issuer = lookup(each.value, "issuer", null)                                                 #(Optional) Issuer URI. When using Azure Active Directory, this value is the URI of the directory tenant, e.g. https://sts.windows.net/{tenant-guid}/.
    #microsoft {}
    runtime_version               = lookup(each.value, "runtime_version", null)                 #(Optional) The runtime version of the Authentication/Authorization module.
    token_refresh_extension_hours = lookup(each.value, "token_refresh_extension_hours", null)   #(Optional) The number of hours after session token expiration that a session token can be used to call the token refresh API. Defaults to 72.
    token_store_enabled           = lookup(each.value, "token_store_enabled", null)             #(Optional) If enabled the module will durably store platform-specific security tokens that are obtained during login flows. Defaults to false.
    #twitter {}
    unauthenticated_client_action = lookup(each.value, "unauthenticated_client_action", null)   #(Optional) The action to take when an unauthenticated client attempts to access the app. Possible values are AllowAnonymous and RedirectToLoginPage.
  }

# - 
# - Connection String (only if present)
# - 
  dynamic "connection_string" {
    for_each = lookup(each.value, "connection_strings", var.null_array)
    content {
      name  = lookup(connection_string.value, "name", null)                                     #(Required) The name of the Connection String.
      type  = lookup(connection_string.value, "type", null)                                     #(Required) The type of the Connection String. Possible values are APIHub, Custom, DocDb, EventHub, MySQL, NotificationHub, PostgreSQL, RedisCache, ServiceBus, SQLAzure and SQLServer.
      value = lookup(connection_string.value, "value", null)                                    #(Required) The value for the Connection String.
    }
  }

  client_affinity_enabled = lookup(each.value, "client_affinity_enabled", null)                 #(Optional) Should the Function App send session affinity cookies, which route client requests in the same session to the same instance?
  client_cert_mode        = lookup(each.value, "client_cert_mode", null)                        #(Optional) The mode of the Function App's client certificates requirement for incoming requests. Possible values are Required and Optional.
  daily_memory_time_quota = lookup(each.value, "daily_memory_time_quota", null)                 #(Optional) The amount of memory in gigabyte-seconds that your application is allowed to consume per day. Setting this value only affects function apps under the consumption plan. Defaults to 0.
  enabled                 = lookup(each.value, "enabled", null)                                 #(Optional) Is the Function App Enabled?
  enable_builtin_logging  = lookup(each.value, "enable_builtin_logging", null)                  #(Optional) Should the built-in logging of this Function App be enabled? Defaults to true.
  https_only              = lookup(each.value, "https_only", null)                              #(Optional) Can the Function Appe only be accessed via HTTPS? Defaults to false.
  os_type                 = lookup(each.value, "os_type", null)                                 #(Optional) A string indicating the Operating System type for this function app.
  # source_control          = lookup(each.value, "source_control", null)                        #(Optional) A source_control block, as defined below.
  version                 = lookup(each.value, "version", null)                                 #(Optional) The runtime version associated with the Function App. Defaults to ~1.

# - 
# - Site Configuration (only if present)
# - 
  dynamic "site_config" {
    for_each = lookup(each.value, "site_config", var.null_array)
    content {
      always_on        = lookup(site_config.value, "always_on", null)                           #(Optional) Should the app be loaded at all times? Defaults to false.

      dynamic "ip_restriction" {
        for_each = lookup(site_config.value, "ip_restriction", var.null_array)
        content {
          ip_address = lookup(ip_restriction.value, "ip_address", null)                  #(Optional) The IP Address used for this IP Restriction in CIDR notation.
          service_tag = lookup(ip_restriction.value, "service_tag", null)                #(Optional) The Service Tag used for this IP Restriction.
          virtual_network_subnet_id = lookup(ip_restriction.value, "virtual_network_subnet_id", null)    #(Optional) The Virtual Network Subnet ID used for this IP Restriction.
          name = lookup(ip_restriction.value, "name", null)                              #(Optional) The name for this IP Restriction.
          priority = lookup(ip_restriction.value, "priority", null)                      #(Optional) The priority for this IP Restriction. Restrictions are enforced in priority order. By default, priority is set to 65000 if not specified.
          action = lookup(ip_restriction.value, "action", null)                          #(Optional) Does this restriction Allow or Deny access for this IP range. Defaults to Allow.
          
          dynamic "headers" {                                                                 #(Optional) The headers for this specific ip_restriction as defined below.
            for_each = lookup(site_config.value, "headers", var.null_array)
            content {   
              x_azure_fdid      = lookup(headers.value, "x_azure_fdid", null)                 #(Optional) A list of allowed Azure FrontDoor IDs in UUID notation with a maximum of 8.
              x_fd_health_probe = lookup(headers.value, "x_fd_health_probe", null)            #(Optional) A list to allow the Azure FrontDoor health probe header. Only allowed value is "1".
              x_forwarded_for   = lookup(headers.value, "x_forwarded_for", null)              #(Optional) A list of allowed 'X-Forwarded-For' IPs in CIDR notation with a maximum of 8
              x_forwarded_host  = lookup(headers.value, "x_forwarded_host", null)             #(Optional) A list of allowed 'X-Forwarded-Host' domains with a maximum of 8.              
            }   
          }
        }
      }

      dynamic "cors" {
        for_each = lookup(site_config.value, "cors", var.null_array)
        content {
          allowed_origins     = lookup(cors.value, "allowed_origins", null)                  #(Optional) A list of origins which should be able to make cross-origin calls. * can be used to allow all calls.
          support_credentials = lookup(cors.value, "support_credentials", null)              #(Optional) Are credentials supported?
        }
      }

      ftps_state               = lookup(site_config.value, "ftps_state", null)               #(Optional) State of FTP / FTPS service for this App Service. Possible values include: AllAllowed, FtpsOnly and Disabled.
      health_check_path        = lookup(site_config.value, "health_check_path", null)        #(Optional) The health check path to be pinged by App Service.
      http2_enabled            = lookup(site_config.value, "http2_enabled", null)            #(Optional) Is HTTP2 Enabled on this App Service? Defaults to false.

      scm_use_main_ip_restriction = lookup(site_config.value, "scm_use_main_ip_restriction", null) #(Optional) IP security restrictions for scm to use main. Defaults to false.

      dynamic "scm_ip_restriction" {                                                          #(Optional) A List of objects representing ip restrictions as defined below.
        for_each = lookup(site_config.value, "scm_ip_restriction", var.null_array)
        content {
          ip_address = lookup(scm_ip_restrictions.value, "ip_address", null)                  #(Optional) The IP Address used for this IP Restriction in CIDR notation.
          service_tag = lookup(scm_ip_restrictions.value, "service_tag", null)                #(Optional) The Service Tag used for this IP Restriction.
          virtual_network_subnet_id = lookup(scm_ip_restrictions.value, "virtual_network_subnet_id", null)    #(Optional) The Virtual Network Subnet ID used for this IP Restriction.
          name = lookup(scm_ip_restrictions.value, "name", null)                              #(Optional) The name for this IP Restriction.
          priority = lookup(scm_ip_restrictions.value, "priority", null)                      #(Optional) The priority for this IP Restriction. Restrictions are enforced in priority order. By default, priority is set to 65000 if not specified.
          action = lookup(scm_ip_restrictions.value, "action", null)                          #(Optional) Does this restriction Allow or Deny access for this IP range. Defaults to Allow.
          
          dynamic "headers" {                                                                 #(Optional) The headers for this specific ip_restriction as defined below.
            for_each = lookup(site_config.value, "headers", var.null_array)
            content {   
              x_azure_fdid      = lookup(headers.value, "x_azure_fdid", null)                 #(Optional) A list of allowed Azure FrontDoor IDs in UUID notation with a maximum of 8.
              x_fd_health_probe = lookup(headers.value, "x_fd_health_probe", null)            #(Optional) A list to allow the Azure FrontDoor health probe header. Only allowed value is "1".
              x_forwarded_for   = lookup(headers.value, "x_forwarded_for", null)              #(Optional) A list of allowed 'X-Forwarded-For' IPs in CIDR notation with a maximum of 8
              x_forwarded_host  = lookup(headers.value, "x_forwarded_host", null)             #(Optional) A list of allowed 'X-Forwarded-Host' domains with a maximum of 8.              
            }   
          }
        }        
      }

      #(Optional) A List of objects representing ip restrictions as defined below.
      java_version              = lookup(site_config.value, "java_version", null)                                                                                                                                                                                                                                                                                                      #(Optional) The version of Java to use. If specified java_container and java_container_version must also be specified. Possible values are 1.7, 1.8 and 11.
      linux_fx_version          = lookup(site_config.value, "linux_fx_version", null) == null ? null : lookup(site_config.value, "linux_fx_version_local_file_path", null) == null ? lookup(site_config.value, "linux_fx_version", null) : "${lookup(site_config.value, "linux_fx_version", null)}|${filebase64(lookup(site_config.value, "linux_fx_version_local_file_path", null))}" #(Optional) Linux App Framework and version for the App Service. Possible options are a Docker container (DOCKER|<user/image:tag>), a base-64 encoded Docker Compose file (COMPOSE|${filebase64("compose.yml")}) or a base-64 encoded Kubernetes Manifest (KUBE|${filebase64("kubernetes.yml")}).
      min_tls_version           = lookup(site_config.value, "min_tls_version", null)                                                                                                                                                                                                                                                                                                   #(Optional) The minimum supported TLS version for the app service. Possible values are 1.0, 1.1, and 1.2. Defaults to 1.2 for new app services.
      pre_warmed_instance_count = lookup(site_config.value, "pre_warmed_instance_count", null)
      scm_type                  = lookup(site_config.value, "scm_type", null)                                                                                                                                                                                                                                                                                                          #(Optional) The type of Source Control enabled for this App Service. Defaults to None. Possible values are: BitbucketGit, BitbucketHg, CodePlexGit, CodePlexHg, Dropbox, ExternalGit, ExternalHg, GitHub, LocalGit, None, OneDrive, Tfs, VSO and VSTSRM
      use_32_bit_worker_process = lookup(site_config.value, "use_32_bit_worker_process", null)                                                                                                                                                                                                                                                                                         #(Optional) Should the App Service run in 32 bit mode, rather than 64 bit mode? NOTE: when using an App Service Plan in the Free or Shared Tiers use_32_bit_worker_process must be set to true.                                                                                                                                                                                                                                                                                         #(Optional) The name of the Virtual Network which this App Service should be attached to.
      websockets_enabled        = lookup(site_config.value, "websockets_enabled", null)                                                                                                                                                                                                                                                                                                #(Optional) Should WebSockets be enabled?
    }
  }

# - 
# - Identity Configuration (only if present - defaults to SystemAssigned)
# - 
  dynamic "identity" {
    for_each = lookup(each.value, "identity", var.null_array)
    content {
      type         = lookup(identity.value, "type", null)                                     # (Required) Specifies the identity type of the App Service. Possible values are SystemAssigned (where Azure will generate a Service Principal for you), UserAssigned where you can specify the Service Principal IDs in the identity_ids field, and SystemAssigned, UserAssigned which assigns both a system managed identity as well as the specified user assigned identities. NOTE: When type is set to SystemAssigned, The assigned principal_id and tenant_id can be retrieved after the App Service has been created. More details are available below.
      identity_ids = lookup(identity.value, "identity_ids", null)                             # (Optional) Specifies a list of user managed identity ids to be assigned. Required if type is UserAssigned.

    }
  }

  tags = data.azurerm_resource_group.rg.tags
}