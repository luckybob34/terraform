# - 
# - General
# -
location            = "East US 2"
resource_group_name = "test-appservice-rg"
resource_group_lock = "rg-lock"
environment         = "test"

# - 
# - Resource Tags
# -
resource_tags = {
  "service"         = "Azure App Service"
  "environment"     = "test"
}

# -
# - App Service and App Service Plans
# -

# App Service Plans
app_service_plans = { 
  primary_asp = {
    team                         = "app"               #(Mandatory)
    name                         = "asptest"           #(Mandatory)
    instance                     = "01"                #(Mandatory)
    location                     = "East US 2"         #(Required) Location of the App Service Plan
    sku_tier                     = "Standard"          #(Required) Specifies the plan's pricing tier.
    sku_size                     = "S1"                #(Required) Specifies the plan's instance size.
    maximum_elastic_worker_count = 1                   #(Optional) The maximum number of total workers allowed for this ElasticScaleEnabled App Service Plan.    
  }
  secondary_asp = {
    team                         = "app"               #(Mandatory)
    name                         = "asptest"           #(Mandatory)
    instance                     = "02"                #(Mandatory)
    location                     = "Central US"        #(Required) Location of the App Service Plan
    sku_tier                     = "Standard"          #(Required) Specifies the plan's pricing tier.
    sku_size                     = "S1"                #(Required) Specifies the plan's instance size.
    maximum_elastic_worker_count = 1                   #(Optional) The maximum number of total workers allowed for this ElasticScaleEnabled App Service Plan.    
  }  
}

# App Service Plans - Autoscale Settings
monitor_autoscale_settings = {
  primary_asp = {
    team                         = "app"               #(Mandatory)    
    name                         = "asptest-autoscale" #(Mandatory)
    instance                     = "01"                #(Mandatory)
    location                     = "East US 2"
    app_service_plan_key         = "primary_asp"       #(Mandatory)

    enabled                      = true                #(Optional) Specifies whether automatic scaling is enabled for the target resource. Defaults to true.
    profile = [                                        #(Required) Specifies one or more (up to 20) profile blocks as defined below.
      {
        name                     = "Default-Profile"   #(Required) Specifies the name of the profile.
        #Capacity
        default                  = "1"                 #(Required) The number of instances that are available for scaling if metrics are not available for evaluation. The default is only used if the current instance count is lower than the default. Valid values are between 0 and 1000.
        maximum                  = "1"                 #(Required) The maximum number of instances for this resource. Valid values are between 0 and 1000.      
        minimum                  = "1"                 #(Required) The minimum number of instances for this resource. Valid values are between 0 and 1000.
      }
    ]
  }
  secondary_asp = {
    team                         = "app"               #(Mandatory)    
    name                         = "asptest-autoscale" #(Mandatory)
    instance                     = "01"                #(Mandatory)
    location                     = "Central US"
    app_service_plan_key         = "secondary_asp"     #(Mandatory)

    enabled                      = true                #(Optional) Specifies whether automatic scaling is enabled for the target resource. Defaults to true.
    profile = [                                        #(Required) Specifies one or more (up to 20) profile blocks as defined below.
      {
        name                     = "Default-Profile"   #(Required) Specifies the name of the profile.
        #Capacity
        default                  = "1"                 #(Required) The number of instances that are available for scaling if metrics are not available for evaluation. The default is only used if the current instance count is lower than the default. Valid values are between 0 and 1000.
        maximum                  = "1"                 #(Required) The maximum number of instances for this resource. Valid values are between 0 and 1000.      
        minimum                  = "1"                 #(Required) The minimum number of instances for this resource. Valid values are between 0 and 1000.
      }
    ]
  }  
}

# App Services
app_services = {
  primary_as = {
    team                         = "app"               #(Mandatory)    
    name                         = "testing-as"        #(Mandatory) Core name of the App Service
    instance                     = "01"                #(Mandatory) Priority postfix for App Service name
    location                     = "East US 2"         #(Required) Location of App Service
    app_service_plan_key         = "primary_asp"       #(Required) The Key from azurerm_app_service_plan map the  of the App Service Plan within which to create this App Service.
    https_only                   = true                #(Optional) Can the App Service only be accessed via HTTPS? Defaults to false.
    # - App Settings
    app_settings = {
        "someName" = "someValue"
    }

     # - Site Configuration Block (Optional)
    site_config = [
      { 
        scm_use_main_ip_restriction = true                    #(Optional) IP security restrictions for scm to use main. Defaults to false.
        default_documents           = [                       #(Optional) The ordering of default documents to load, if an address isn't specified.
                                        "Default.htm",
                                        "Default.html",
                                        "Default.asp",
                                        "index.htm",
                                        "index.html",
                                        "iisstart.htm",
                                        "default.aspx",
                                        "index.php",
                                        "hostingstart.html"
                                      ]                  
        dotnet_framework_version    = "v4.0"                  #(Optional) The version of the .net framework's CLR used in this App Service. Possible values are v2.0 (which will use the latest version of the .net framework for the .net CLR v2 = lookup(site_config.value, "", null) #currently .net 3.5) and v4.0 (which corresponds to the latest version of the .net CLR v4 = lookup(site_config.value, "", null) #which at the time of writing is .net 4.7.1). For more information on which .net CLR version to use based on the .net framework you're targeting = lookup(site_config.value, "", null) #please see this table. Defaults to v4.0.
        ftps_state                  = "AllAllowed"            #(Optional) State of FTP / FTPS service for this App Service. Possible values include: AllAllowed, FtpsOnly and Disabled.
        number_of_workers           = 1                       #(Optional) The scaled number of workers (for per site scaling) of this App Service. Requires that per_site_scaling is enabled on the azurerm_app_service_plan.
        min_tls_version             = "1.2"                   #(Optional) The minimum supported TLS version for the app service. Possible values are 1.0, 1.1, and 1.2. Defaults to 1.2 for new app services.
        php_version                 = "5.6"                   #(Optional) The version of PHP to use in this App Service. Possible values are 5.5, 5.6, 7.0, 7.1 and 7.2.
        use_32_bit_worker_process   = "true"                  #(Optional) Should the App Service run in 32 bit mode, rather than 64 bit mode? NOTE: when using an App Service Plan in the Free or Shared Tiers use_32_bit_worker_process must be set to true.                                                                                                                                                                                           
      },
    ]
  } 
  secondary_as = {
    team                         = "app"               #(Mandatory)    
    name                         = "testing-as"        #(Mandatory) Core name of the App Service
    instance                     = "02"                #(Mandatory) Priority postfix for App Service name
    location                     = "Central US"        #(Required) Location of App Service    
    app_service_plan_key         = "secondary_asp"     #(Required) The Key from azurerm_app_service_plan map the  of the App Service Plan within which to create this App Service.
    https_only                   = true                #(Optional) Can the App Service only be accessed via HTTPS? Defaults to false.
    # - App Settings
    app_settings = {
        "someName" = "someValue"
    }

     # - Site Configuration Block (Optional)
    site_config = [
      { 
        scm_use_main_ip_restriction = true                    #(Optional) IP security restrictions for scm to use main. Defaults to false.
        default_documents           = [                       #(Optional) The ordering of default documents to load, if an address isn't specified.
                                        "Default.htm",
                                        "Default.html",
                                        "Default.asp",
                                        "index.htm",
                                        "index.html",
                                        "iisstart.htm",
                                        "default.aspx",
                                        "index.php",
                                        "hostingstart.html"
                                      ]                  
        dotnet_framework_version    = "v4.0"                  #(Optional) The version of the .net framework's CLR used in this App Service. Possible values are v2.0 (which will use the latest version of the .net framework for the .net CLR v2 = lookup(site_config.value, "", null) #currently .net 3.5) and v4.0 (which corresponds to the latest version of the .net CLR v4 = lookup(site_config.value, "", null) #which at the time of writing is .net 4.7.1). For more information on which .net CLR version to use based on the .net framework you're targeting = lookup(site_config.value, "", null) #please see this table. Defaults to v4.0.
        ftps_state                  = "AllAllowed"            #(Optional) State of FTP / FTPS service for this App Service. Possible values include: AllAllowed, FtpsOnly and Disabled.
        number_of_workers           = 1                       #(Optional) The scaled number of workers (for per site scaling) of this App Service. Requires that per_site_scaling is enabled on the azurerm_app_service_plan.
        min_tls_version             = "1.2"                   #(Optional) The minimum supported TLS version for the app service. Possible values are 1.0, 1.1, and 1.2. Defaults to 1.2 for new app services.
        php_version                 = "5.6"                   #(Optional) The version of PHP to use in this App Service. Possible values are 5.5, 5.6, 7.0, 7.1 and 7.2.
        use_32_bit_worker_process   = "true"                  #(Optional) Should the App Service run in 32 bit mode, rather than 64 bit mode? NOTE: when using an App Service Plan in the Free or Shared Tiers use_32_bit_worker_process must be set to true.                                                                                                                                                                                           
      },
    ]
  }   
}

# - App Service Site Extensions
site_extensions = {}

# -
# - Traffic Manager Profile & Trafic Manager Endpoints
# -

traffic_manager_profiles = {
  testapp = {
    name                         = "testapp"               #(Mandatory)
    team                         = "app"                   #(Mandatory)    
    instance                     = "01"
    traffic_routing_method       = "Weighted"              #(Required) Specifies the algorithm used to route traffic
    #dns_config                                            #(Required) This block specifies the DNS configuration of the Profile
    relative_name                = "test-testapp-app-01"   #(Required) (Unique)
    ttl                          = "100"                   #(Required) 
    # monitor_config                                       #(Required) This block specifies the Endpoint monitoring configuration for the Profile
    protocol                     = "https"                 #(Required) The protocol used by the monitoring checks, supported values are HTTP, HTTPS and TCP.
    port                         = 443                     #(Required) The port number used by the monitoring checks.
    path                         = "/"                     #(Optional) The path used by the monitoring checks. Required when protocol is set to HTTP or HTTPS - cannot be set when protocol is set to TCP.
  }         
}

traffic_manager_endpoints = {
  primary_as = {
    name                        = "testapp"              #(Required) The name of the Traffic Manager endpoint. Changing this forces a new resource to be created.
    team                        = "app"                  #(Mandatory)    
    instance                    = "01"                   #(Required) The priority name of the Traffic Manager endpoint. Changing this forces a new resource to be created.
    traffic_manager_profile_key = "testapp"              #(Required) The name of the Traffic Manager Profile to attach create the Traffic Manager endpoint.
    type                        = "azureEndpoints"       #(Required) The Endpoint type, must be one of: azureEndpoints, externalEndpoints, nestedEndpoints
    weight                      = 100                    #(Optional) Specifies how much traffic should be distributed to this endpoint, this must be specified for Profiles using the Weighted traffic routing method. Supports values between 1 and 1000.
    app_service_key             = "primary_as"           #(Optional) The resource id of an Azure resource to target. This argument must be provided for an endpoint of type azureEndpoints or nestedEndpoints.  
  }
  secondary_as = {
    name                        = "testapp"              #(Required) The name of the Traffic Manager endpoint. Changing this forces a new resource to be created.
    team                        = "app"                  #(Mandatory)    
    instance                    = "02"                   #(Required) The priority name of the Traffic Manager endpoint. Changing this forces a new resource to be created.
    traffic_manager_profile_key = "testapp"              #(Required) The name of the Traffic Manager Profile to attach create the Traffic Manager endpoint.
    type                        = "azureEndpoints"       #(Required) The Endpoint type, must be one of: azureEndpoints, externalEndpoints, nestedEndpoints
    weight                      = 50                     #(Optional) Specifies how much traffic should be distributed to this endpoint, this must be specified for Profiles using the Weighted traffic routing method. Supports values between 1 and 1000.
    app_service_key             = "secondary_as"         #(Optional) The resource id of an Azure resource to target. This argument must be provided for an endpoint of type azureEndpoints or nestedEndpoints.  
  }
}