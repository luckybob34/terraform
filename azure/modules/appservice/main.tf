# -
# - Data gathering
# -
data "azurerm_resource_group" "rg" {
  name = var.app_service_rg
}

# -
# - App Service Plan
# -

resource "azurerm_app_service_plan" "asp1" {
  for_each                     = var.app_service_plans
  name                         = "asp-${each.value["name"]}-${each.value["priority"]}-${var.environment}"
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = var.app_service_location
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
# - App Services
# -
resource "azurerm_app_service" "apps1" {
  for_each            = var.app_services
  name                = "as-${each.value["name"]}-${each.value["priority"]}-${var.environment}"         #(Required) Specifies the name of the App Service. Changing this forces a new resource to be created.
  resource_group_name = data.azurerm_resource_group.rg.name                                             #(Required) The name of the resource group in which to create the App Service.
  location            = var.app_service_location                                                        #(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
  app_service_plan_id = lookup(azurerm_app_service_plan.asp1, each.value["app_service_plan_key"])["id"] #(Required) The ID of the App Service Plan within which to create this App Service.
  app_settings        = lookup(each.value, "app_settings", null)                                        #(Optional) A key-value pair of App Settings.
  
  # -
  # - Authentication Settings for the App Service (disabled by default)
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
# - Backup Configuration (only if present)
# - 
  dynamic "backup" {
    for_each = lookup(each.value, "backup", [])
    content {
      name                = lookup(backup.value, "name", null)                                  #(Required) Specifies the name for this Backup.
      enabled             = lookup(backup.value, "enabled", null)                               #(Required) Is this Backup enabled?
      storage_account_url = lookup(backup.value, "storage_account_url", null)                   #(Optional) The SAS URL to a Storage Container where Backups should be saved.
      dynamic "schedule" {
        for_each = lookup(backup.value, "schedule", var.null_array)
        content {
          frequency_interval       = lookup(schedule.value, "frequency_interval", null)         #(Required) Sets how often the backup should be executed.
          frequency_unit           = lookup(schedule.value, "frequency_unit", null)             #(Optional) Sets the unit of time for how often the backup should be executed. Possible values are Day or Hour.
          keep_at_least_one_backup = lookup(schedule.value, "keep_at_least_one_backup", null)   #(Optional) Should at least one backup always be kept in the Storage Account by the Retention Policy, regardless of how old it is?
          retention_period_in_days = lookup(schedule.value, "retention_period_in_days", null)   #(Optional) Specifies the number of days after which Backups should be deleted.
          start_time               = lookup(schedule.value, "start_time", null)                 #(Optional) Sets when the schedule should start working.
        }
      }
    }
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

  client_affinity_enabled = lookup(each.value, "client_affinity_enabled", null)                 #(Optional) Should the App Service send session affinity cookies, which route client requests in the same session to the same instance?
  client_cert_enabled     = lookup(each.value, "client_cert_enabled", null)                     #(Optional) Does the App Service require client certificates for incoming requests? Defaults to false.
  enabled                 = lookup(each.value, "enabled", null)                                 #(Optional) Is the App Service Enabled?

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

  https_only              = lookup(each.value, "https_only", null)                              #(Optional) Can the App Service only be accessed via HTTPS? Defaults to false.

# - 
# - Log Settings (only if present)
# - 
  dynamic "logs" {
    for_each = lookup(each.value, "logs", var.null_array)
    content {

      dynamic "application_logs" {
        for_each = lookup(logs.value, "application_logs", var.null_array)
        content {
          dynamic "azure_blob_storage" {
            for_each = lookup(application_logs.value, "azure_blob_storage", var.null_array)
            content {
              level             = lookup(azure_blob_storage.value, "level", null)               #(Required) The level at which to log. Possible values include Error, Warning, Information, Verbose and Off. NOTE: this field is not available for http_logs
              sas_url           = lookup(azure_blob_storage.value, "sas_url", null)             #(Required) The URL to the storage container, with a Service SAS token appended. NOTE: there is currently no means of generating Service SAS tokens with the azurerm provider.
              retention_in_days = lookup(azure_blob_storage.value, "retention_in_days", null)   #(Required) The number of days to retain logs for.
            }
          }
        }
      }

      dynamic "http_logs" {
        for_each = lookup(logs.value, "http_logs", var.null_array)
        content {
          dynamic "file_system" {
            for_each = lookup(http_logs.value, "file_system", var.null_array)
            content {
              retention_in_days = lookup(file_system.value, "retention_in_days", null)          #(Required) Default is 1.The number of days to retain logs for.
              retention_in_mb   = lookup(file_system.value, "retention_in_mb", null)            #(Required)  Default is 35. The maximum size in megabytes that http log files can use before being removed.  
            }
          }

          dynamic "azure_blob_storage" {
            for_each = lookup(http_logs.value, "azure_blob_storage", var.null_array)
            content {
              sas_url           = lookup(azure_blob_storage.value, "sas_url", null)             #(Required) The URL to the storage container, with a Service SAS token appended. NOTE: there is currently no means of generating Service SAS tokens with the azurerm provider.
              retention_in_days = lookup(azure_blob_storage.value, "retention_in_days", null)   #(Required) The number of days to retain logs for.
            }
          }
        }
      }
    }
  }

# - 
# - Storage Account (only if present)
# - 
  dynamic "storage_account" {
    for_each = lookup(each.value, "storage_accounts", var.null_array)
    content {
      name         = lookup(storage_account.value, "name", null)                                #(Required) The name of the storage account identifier.
      type         = lookup(storage_account.value, "type", null)                                #(Required) The type of storage. Possible values are AzureBlob and AzureFiles.
      account_name = lookup(storage_account.value, "account_name", null)                        #(Required) The name of the storage account.
      share_name   = lookup(storage_account.value, "share_name", null)                          #(Required) The name of the file share (container name, for Blob storage).
      access_key   = lookup(storage_account.value, "access_key", null)                          #(Required) The access key for the storage account.
      mount_path   = lookup(storage_account.value, "mount_path", null)                          #(Optional) The path to mount the storage within the site's runtime environment.

    }
  }

# - 
# - Site Configuration (only if present)
# - 
  dynamic "site_config" {
    for_each = lookup(each.value, "site_config", var.null_array)
    content {
      always_on        = lookup(site_config.value, "always_on", null)                           #(Optional) Should the app be loaded at all times? Defaults to false.
      app_command_line = lookup(site_config.value, "app_command_line", null)                    #(Optional) App command line to launch, e.g. /sbin/myserver -b 0.0.0.0.

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

      default_documents        = lookup(site_config.value, "default_documents", null)        #(Optional) The ordering of default documents to load, if an address isn't specified.
      dotnet_framework_version = lookup(site_config.value, "dotnet_framework_version", null) #(Optional) The version of the .net framework's CLR used in this App Service. Possible values are v2.0 (which will use the latest version of the .net framework for the .net CLR v2 = lookup(site_config.value, "", null) #currently .net 3.5) and v4.0 (which corresponds to the latest version of the .net CLR v4 = lookup(site_config.value, "", null) #which at the time of writing is .net 4.7.1). For more information on which .net CLR version to use based on the .net framework you're targeting = lookup(site_config.value, "", null) #please see this table. Defaults to v4.0.
      ftps_state               = lookup(site_config.value, "ftps_state", null)               #(Optional) State of FTP / FTPS service for this App Service. Possible values include: AllAllowed, FtpsOnly and Disabled.
      health_check_path        = lookup(site_config.value, "health_check_path", null)        #(Optional) The health check path to be pinged by App Service.
      number_of_workers        = lookup(site_config.value, "number_of_workers", null)        #(Optional) The scaled number of workers (for per site scaling) of this App Service. Requires that per_site_scaling is enabled on the azurerm_app_service_plan.
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
      java_container            = lookup(site_config.value, "java_container", null)                                                                                                                                                                                                                                                                                                    #(Optional) The Java Container to use. If specified java_version and java_container_version must also be specified. Possible values are JETTY and TOMCAT.
      java_container_version    = lookup(site_config.value, "java_container_version", null)                                                                                                                                                                                                                                                                                            #(Optional) The version of the Java Container to use. If specified java_version and java_container must also be specified.
      local_mysql_enabled       = lookup(site_config.value, "local_mysql_enabled", null)                                                                                                                                                                                                                                                                                               #(Optional) Is "MySQL In App" Enabled? This runs a local MySQL instance with your app and shares resources from the App Service plan.NOTE: MySQL In App is not intended for production environments and will not scale beyond a single instance. Instead you may wish to use Azure Database for MySQL.
      linux_fx_version          = lookup(site_config.value, "linux_fx_version", null) == null ? null : lookup(site_config.value, "linux_fx_version_local_file_path", null) == null ? lookup(site_config.value, "linux_fx_version", null) : "${lookup(site_config.value, "linux_fx_version", null)}|${filebase64(lookup(site_config.value, "linux_fx_version_local_file_path", null))}" #(Optional) Linux App Framework and version for the App Service. Possible options are a Docker container (DOCKER|<user/image:tag>), a base-64 encoded Docker Compose file (COMPOSE|${filebase64("compose.yml")}) or a base-64 encoded Kubernetes Manifest (KUBE|${filebase64("kubernetes.yml")}).
      windows_fx_version        = lookup(site_config.value, "windows_fx_version", null)                                                                                                                                                                                                                                                                                                #(Optional) The Windows Docker container image (DOCKER|<user/image:tag>)
      managed_pipeline_mode     = lookup(site_config.value, "managed_pipeline_mode", null)                                                                                                                                                                                                                                                                                             #(Optional) The Managed Pipeline Mode. Possible values are Integrated and Classic. Defaults to Integrated.
      min_tls_version           = lookup(site_config.value, "min_tls_version", null)                                                                                                                                                                                                                                                                                                   #(Optional) The minimum supported TLS version for the app service. Possible values are 1.0, 1.1, and 1.2. Defaults to 1.2 for new app services.
      php_version               = lookup(site_config.value, "php_version", null)                                                                                                                                                                                                                                                                                                       #(Optional) The version of PHP to use in this App Service. Possible values are 5.5, 5.6, 7.0, 7.1 and 7.2.
      python_version            = lookup(site_config.value, "python_version", null)                                                                                                                                                                                                                                                                                                    #(Optional) The version of Python to use in this App Service. Possible values are 2.7 and 3.4.
      remote_debugging_enabled  = lookup(site_config.value, "remote_debugging_enabled", null)                                                                                                                                                                                                                                                                                          #(Optional) Is Remote Debugging Enabled? Defaults to false.
      remote_debugging_version  = lookup(site_config.value, "remote_debugging_version", null)                                                                                                                                                                                                                                                                                          #(Optional) Which version of Visual Studio should the Remote Debugger be compatible with? Possible values are VS2012, VS2013, VS2015 and VS2017.
      scm_type                  = lookup(site_config.value, "scm_type", null)                                                                                                                                                                                                                                                                                                          #(Optional) The type of Source Control enabled for this App Service. Defaults to None. Possible values are: BitbucketGit, BitbucketHg, CodePlexGit, CodePlexHg, Dropbox, ExternalGit, ExternalHg, GitHub, LocalGit, None, OneDrive, Tfs, VSO and VSTSRM
      use_32_bit_worker_process = lookup(site_config.value, "use_32_bit_worker_process", null)                                                                                                                                                                                                                                                                                         #(Optional) Should the App Service run in 32 bit mode, rather than 64 bit mode? NOTE: when using an App Service Plan in the Free or Shared Tiers use_32_bit_worker_process must be set to true.                                                                                                                                                                                                                                                                                         #(Optional) The name of the Virtual Network which this App Service should be attached to.
      websockets_enabled        = lookup(site_config.value, "websockets_enabled", null)                                                                                                                                                                                                                                                                                                #(Optional) Should WebSockets be enabled?
    }
  }

# -
# - Source Control
# -
  dynamic "source_control" {
    for_each = lookup(each.value, "source_control", var.null_array)
    content {
      repo_url           = lookup(source_control.value, "repo_url", null)           #(Required) The URL of the source code repository.
      branch             = lookup(source_control.value, "branch", null)             #(Optional) The branch of the remote repository to use. Defaults to 'master'.
      manual_integration = lookup(source_control.value, "manual_integration", null) #(Optional) Limits to manual integration. Defaults to false if not specified.
      rollback_enabled   = lookup(source_control.value, "rollback_enabled", null)   #(Optional) Enable roll-back for the repository. Defaults to false if not specified.
      use_mercurial      = lookup(source_control.value, "use_mercurial", null)      #(Optional) Use Mercurial if true, otherwise uses Git.    
    }
  }

  tags = data.azurerm_resource_group.rg.tags
}


resource "azurerm_monitor_autoscale_setting" "mas1" {
  depends_on          = [azurerm_app_service_plan.asp1]
  for_each            = var.monitor_autoscale_settings
  name                = "mas-${each.value["name"]}-${each.value["priority"]}-${var.environment}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.app_service_location

  #(Required) Specifies the resource ID of the resource that the autoscale setting should be added to.
  target_resource_id  = lookup(azurerm_app_service_plan.asp1, each.value["app_service_plan_key"])["id"]
  enabled             = lookup(each.value, "enabled", null)                         #(Optional) Specifies whether automatic scaling is enabled for the target resource. Defaults to true.

  dynamic "profile" {                                                               #(Required) Specifies one or more (up to 20) profile blocks as defined below.
    for_each = lookup(each.value, "profile", [])
    content {
      name = profile.value["name"]                                                  #(Required) Specifies the name of the profile.

      capacity {                                                                    #(Required) A capacity block as defined below.
        default = profile.value["default"]                                          #(Required) The number of instances that are available for scaling if metrics are not available for evaluation. The default is only used if the current instance count is lower than the default. Valid values are between 0 and 1000.
        maximum = profile.value["maximum"]                                          #(Required) The maximum number of instances for this resource. Valid values are between 0 and 1000.      
        minimum = profile.value["minimum"]                                          #(Required) The minimum number of instances for this resource. Valid values are between 0 and 1000.
      }
      
      dynamic "rule" {                                                              #(Optional) One or more (up to 10) rule blocks as defined below.
        for_each = lookup(profile.value, "rule", var.null_array)
        content {
          dynamic "metric_trigger" {                                                #(Required) A metric_trigger block as defined below.
            for_each = lookup(rule.value, "metric_trigger", null)
            content {
              metric_name        = metric_trigger.value["metric_name"]              #(Required) The name of the metric that defines what the rule monitors, such as Percentage CPU for Virtual Machine Scale Sets and CpuPercentage for App Service Plan.
              metric_resource_id = metric_trigger.value["metric_resource_id"]       #(Required) The ID of the Resource which the Rule monitors.
              operator           = metric_trigger.value["operator"]                 #(Required) Specifies the operator used to compare the metric data and threshold. Possible values are: Equals, NotEquals, GreaterThan, GreaterThanOrEqual, LessThan, LessThanOrEqual.
              statistic          = metric_trigger.value["statistic"]                #(Required) Specifies how the metrics from multiple instances are combined. Possible values are Average, Min and Max.
              time_aggregation   = metric_trigger.value["time_aggregation"]         #(Required) Specifies how the data that's collected should be combined over time. Possible values include Average, Count, Maximum, Minimum, Last and Total. Defaults to Average.
              time_grain         = metric_trigger.value["time_grain"]               #(Required) Specifies the granularity of metrics that the rule monitors, which must be one of the pre-defined values returned from the metric definitions for the metric. This value must be between 1 minute and 12 hours an be formatted as an ISO 8601 string.
              time_window        = metric_trigger.value["time_window"]              #(Required) Specifies the time range for which data is collected, which must be greater than the delay in metric collection (which varies from resource to resource). This value must be between 5 minutes and 12 hours and be formatted as an ISO 8601 string.
              threshold          = metric_trigger.value["threshold"]                #(Required) Specifies the threshold of the metric that triggers the scale action.
              metric_namespace   = lookup(metric_trigger, "metric_namespace", null) #(Optional) The namespace of the metric that defines what the rule monitors, such as microsoft.compute/virtualmachinescalesets for Virtual Machine Scale Sets.
              
              dynamic "dimensions" {                                                #(Optional) One or more dimensions block as defined below.
                for_each = lookup(metric_trigger.value, "dimensions", var.null_array)
                content {
                  name     = dimensions.value["name"]                               #(Required) The name of the dimension.
                  operator = dimensions.value["operator"]                           #(Required) The dimension operator. Possible values are Equals and NotEquals. Equals means being equal to any of the values. NotEquals means being not equal to any of the values.
                  values   = dimensions.value["values"]                             #(Required) A list of dimension values.
                }
              }
            }
          }
          dynamic "scale_action" {                                                  #(Required) A scale_action block as defined below.
            for_each = lookup(rule.value, "scale_action", [])
            content {
              cooldown  = scale_action.value["cooldown"]                            #(Required) The amount of time to wait since the last scaling action before this action occurs. Must be between 1 minute and 1 week and formatted as a ISO 8601 string.
              direction = scale_action.value["direction"]                           #(Required) The scale direction. Possible values are Increase and Decrease.
              type      = scale_action.value["type"]                                #(Required) The type of action that should occur. Possible values are ChangeCount, ExactCount and PercentChangeCount.
              value     = scale_action.value["value"]                               #(Required) The number of instances involved in the scaling action. Defaults to 1.              
            }
          }                    
        }
      }

      dynamic "fixed_date" {                                                        #(Optional) A fixed_date block as defined below. This cannot be specified if a recurrence block is specified.
        for_each = lookup(profile.value, "fixed_date", var.null_array)
        content {
          end      = fixed_date.value[""]                                           #(Required) Specifies the end date for the profile, formatted as an RFC3339 date string.
          start    = fixed_date.value[""]                                           #(Required) Specifies the start date for the profile, formatted as an RFC3339 date string.
          timezone = lookup(fixed_date.value, "timezone", null)                     #(Optional) The Time Zone of the start and end times. A list of possible values can be found here. Defaults to UTC.          
        }
      }
      
      dynamic "recurrence" {                                                        #(Optional) A recurrence block as defined below. This cannot be specified if a fixed_date block is specified.      
        for_each = lookup(profile.value, "recurrence", var.null_array)
        content {
          timezone = recurrence.value["timezone"]                                   #(Required) The Time Zone used for the hours field. A list of possible values can be found here. Defaults to UTC.
          days     = recurrence.value["days"]                                       #(Required) A list of days that this profile takes effect on. Possible values include Monday, Tuesday, Wednesday, Thursday, Friday, Saturday and Sunday.
          hours    = recurrence.value["hours"]                                      #(Required) A list containing a single item, which specifies the Hour interval at which this recurrence should be triggered (in 24-hour time). Possible values are from 0 to 23.
          minutes  = recurrence.value["minutes"]                                    #(Required) A list containing a single item which specifies the Minute interval at which this recurrence should be triggered.          
        }
      }
    }
  }
  
  dynamic "notification" {                                                          #(Optional) Specifies a notification block as defined below.
    for_each = lookup(each.value, "notification", var.null_array)
    content {
      dynamic "email" {                                                             #(Required) A email block as defined below.
        for_each = lookup(notification.value, "email", [])
        content {
          send_to_subscription_administrator    = lookup(email.value, "send_to_subscription_administrator", null)     #(Optional) Should email notifications be sent to the subscription administrator? Defaults to false.
          send_to_subscription_co_administrator = lookup(email.value, "send_to_subscription_co_administrator", null)  #(Optional) Should email notifications be sent to the subscription co-administrator? Defaults to false.
          custom_emails                         = lookup(email.value, "custom_emails", null)                          #(Optional) Specifies a list of custom email addresses to which the email notifications will be sent.
        }
      }
      dynamic "webhook" {                                                           #(Optional) One or more webhook blocks as defined below.      
        for_each = lookup(notification.value, "webhook", [])
        content {
          service_uri = webhook.value["service_url"]                                #(Required) The HTTPS URI which should receive scale notifications.
          properties  = lookup(webhook.value, "properties", null)                   #(Optional) A map of settings.
        }
      }
    }
  }

  tags = data.azurerm_resource_group.rg.tags

}

resource "azurerm_template_deployment" "temp1" {
  depends_on            = [azurerm_app_service.apps1]
  for_each              = var.site_extensions
  name                  = "as-se-${each.value["name"]}-${var.environment}"
  resource_group_name   = data.azurerm_resource_group.rg.name
  template_body         = file("./modules/appservice/arm/siteextensions.json")

  parameters = {
    "siteName"          = lookup(azurerm_app_service.apps1, each.value["app_service_key"])["name"]
    "extensionName"     = each.value["extensionName"]
    "extensionVersion"  = each.value["extensionVersion"]
  }

  deployment_mode       = "Incremental"
}