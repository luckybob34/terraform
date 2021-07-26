# - 
# - General
# -
location                     = "East US 2"
resource_group_name          = "DEV-App-Ecomm-ARG"
resource_group_lock          = "rg-lock"
environment                  = "dev"

# - 
# - Resource Tags
# -
resource_tags = {
  "app"         = "RL Ecomm"
  "environment" = "dev"
}

# -
# - Virtual Network, User Defined Routes and Network Security Groups
# - 
virtual_networks = {
  vnet1 = {
    name                     = "test"
    team                     = "app"
    instance                 = "01"
    location                 = "East US 2"
    address_space            = ["10.0.0.0/16"]

    tags = {
     "service"  = "vnet"
    }     
  }    
}

# -
# - Network Security Groups
# -
network_security_groups = {
  nsg_1 = {
    name     = "ecomm"
    team     = "app"
    instance = "01"    
    location = "East US 2"
    security_rule = [
      {
        name                       = "AllowWAGProbeFromInternet"
        description                = "Allow WAF health monitoring from Internet to public WAG subnet"        
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "65200-65535"
        source_address_prefix      = "*"
        destination_address_prefix = "*"        
      },
      {
        name                       = "AllowTrafficManager"
        description                = "Allow traffic from traffic manager"
        priority                   = 300
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "AzureTrafficManager"
        destination_address_prefix = "10.0.0.0/24"     
      },     
    ]
    tags = {
     "service" = "nsg"    
    } 
  }  
}

# -
# - Subnets
# - 
subnets = {
  # Primary vnet
  subnet_agw1 = {
    name                   = "AppGateway"
    vnet_key               = "vnet1"
    address_prefixes       = ["10.0.0.0/24"]
    service_endpoints      = ["Microsoft.Web", "Microsoft.KeyVault"]
  }
}

# -
# - Network Security Group Association
# - 
network_security_group_association = {
  nsga1 = {
    subnet_key = "subnet_agw1"
    nsg_key    = "nsg_1"
  } 
}

# -
# - Application Gateway
# -

# Public IP
public_ips = {
  # Primary Public IP
  primary_pip = {
  name                    = "test" 
  team                    = "app"
  instance                = "01"
  location                = "East US 2"                   #(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
  sku                     = "Standard"                    #(Optional) The SKU of the Public IP. Accepted values are Basic and Standard. Defaults to Basic.
  allocation_method       = "Static"                      #(Required) Defines the allocation method for this IP address. Possible values are Static or Dynamic.
  domain_name_label       = "dev-app-test-01"

  tags = {
      "service"  = "public ip"
      "priority" = "primary"
    }
  }  
}

# Application Gateways
application_gateways = {
  primary_agw = {
    name                = "test"
    team                = "app"
    instance            = "01"
    location            = "East US 2"

    # - Backend Address Pool
    backend_address_pool = {                                                                                          #(Required) One or more backend_address_pool blocks
      test = {
        name         = "teste"                                                                                    #(Required) The name of the Backend Address Pool.
        fqdns        = ["test.azurewebsites.net"]                                                     #(Optional) A list of FQDN's which should be part of the Backend Address Pool.
      }
      stage = {
        name         = "stage"                                                                                    #(Required) The name of the Backend Address Pool.
        ip_addresses = ["stage.azurewebsites.net"]                                                                             #(Optional) A list of IP Addresses which should be part of the Backend Address Pool.      
      } 
    }
    # - Backend Http Settings
    backend_http_settings = {                                                                                         #(Required) One or more backend_http_settings blocks
      dev_https_test = {
        cookie_based_affinity               = "Disabled"                                                              #(Required) Is Cookie-Based Affinity enabled? Possible values are Enabled and Disabled.
        affinity_cookie_name                = "ApplicationGatewayAffinity"                                            #(Optional) The name of the affinity cookie.
        name                                = "dev-https-test-us"                                                     #(Required) The name of the Backend HTTP Settings Collection.
        port                                = "443"                                                                   #(Required) The port which should be used for this Backend HTTP Settings Collection.
        probe_name                          = "dev-health-test-us"                                                    #(Optional) The name of an associated HTTP Probe.
        protocol                            = "Https"                                                                 #(Required) The Protocol which should be used. Possible values are Http and Https.
        request_timeout                     = 60                                                                      #(Required) The request timeout in seconds, which must be between 1 and 86400 seconds.
        host_name                           = "dev.test.com"                                                          #(Optional) Host header to be sent to the backend servers. Cannot be set if pick_host_name_from_backend_address is set to true.
      }
    }

    # - 
    # - Frontend Ip Configurations
    # - 
    frontend_ip_configuration = {                                                                                        #(Required) One or more frontend_ip_configuration blocks
      frontend_1 = { 
        name                          = "appGwPublicFrontendIp"                                                          #(Required) The name of the Frontend IP Configuration.
        public_ip_key                 = "primary_pip"                                                                    #(Optional) The ID of a Public IP Address which the Application Gateway should use. The allocation method for the Public IP Address depends on the sku of this Application Gateway. Please refer to the Azure documentation for public IP addresses for details.
      }
    }

    # - 
    # - Frontend Port
    # - 
    frontend_port = {                                                                                                 #(Required) One or more frontend_port blocks as defined below.
      port_443 = {
        name = "port_443"                                                                                             #(Required) The name of the Frontend Port.
        port = "443"                                                                                                  #(Required) The port used for this Frontend Port.      
      }
    }

    # - 
    # - Gateway Ip Configurations
    # - 
    gateway_ip_configuration = {                                                                                      #(Required) One or more gateway_ip_configuration blocks
      appGatewayIpConfig = {
        name       = "appGatewayIpConfig"                                                                             #(Required) The Name of this Gateway IP Configuration.
        subnet_key = "subnet_agw1"                                                                                    #(Required) The ID of the Subnet which the Application Gateway should be connected to. 
      }
    }

    # - 
    # - Http Listeners
    # - 
    http_listener = {                                                                                                 #(Required) One or more http_listener blocks
      dev_test_com = {
        name                           = "dev.test.com"                                                               #(Required) The Name of the HTTP Listener.
        frontend_ip_configuration_name = "appGwPublicFrontendIp"                                                      #(Required) The Name of the Frontend IP Configuration used for this HTTP Listener.
        frontend_port_name             = "port_443"                                                                   #(Required) The Name of the Frontend Port use for this HTTP Listener.
        host_name                      = "dev.test.com"                                                               #(Optional) The Hostname which should be used for this HTTP Listener. Setting this value changes Listener Type to 'Multi site'.
        protocol                       = "Https"                                                                      #(Required) The Protocol to use for this HTTP Listener. Possible values are Http and Https.
        require_sni                    = true                                                                         #(Optional) Should Server Name Indication be Required? Defaults to false.
        ssl_certificate_name           = "wildcard.test.com"                                                          #(Optional) The name of the associated SSL Certificate which should be used for this HTTP Listener.
      }               
    }

    # - 
    # - Request Routing Rule
    # - 
    request_routing_rule = {                                                                                          #(Required) One or more request_routing_rule blocks
      dev_path = {
        name                        = "dev-path-test"
        rule_type                   = "PathBasedRouting"
        http_listener_name          = "dev.test.com"
        url_path_map_name           = "dev-path-us"
      }                   
    }

    # - 
    # - Sku
    # - 
    sku = {                                                                                                           #(Required) A sku block
      sku_1 = {
        name     = "Standard_v2"                                                                                      #(Required) The Name of the SKU to use for this Application Gateway. Possible values are Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2.
        tier     = "Standard_v2"                                                                                      #(Required) The Tier of the SKU to use for this Application Gateway. Possible values are Standard, Standard_v2, WAF and WAF_v2.
        #capacity = 1                                                                                                  #(Required) The Capacity of the SKU to use for this Application Gateway. When using a V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU. This property is optional if autoscale_configuration is set.      
      }
    }

    # - 
    # - Authentication Certificate
    # - 
    # authentication_certificate = {                                                                                    #(Optional) One or more authentication_certificate blocks
    #   {
    #     name = ""                                                                                                     #(Required) The Name of the Authentication Certificate to use.
    #     data = ""                                                                                                     #(Required) The contents of the Authentication Certificate which should be used.      
    #   }
    # }

    # - 
    # - Trusted Root Certificates
    # - 
    # trusted_root_certificate = {                                                                                      #(Optional) One or more trusted_root_certificate blocks
    #   {
    #     name = ""                                                                                                     #(Required) The Name of the Trusted Root Certificate to use.
    #     data = ""                                                                                                     #(Required) The contents of the Trusted Root Certificate which should be used.      
    #   }
    # }

    # - 
    # - SSL Policy
    # - 
    # ssl_policy = {                                                                                                    #(Optional) a ssl policy block
    #  {
    #     disabled_protocols   = ""                                                                                     #(Optional) A list of SSL Protocols which should be disabled on this Application Gateway. Possible values are TLSv1_0, TLSv1_1 and TLSv1_2.
    #     policy_type          = ""                                                                                     #(Optional) The Type of the Policy. Possible values are Predefined and Custom.
    #     policy_name          = ""                                                                                     #(Optional) The Name of the Policy e.g AppGwSslPolicy20170401S. Required if policy_type is set to Predefined. Possible values can change over time and are published here https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-ssl-policy-overview. Not compatible with disabled_protocols.
    #     cipher_suites        = ""                                                                                     #(Optional) A List of accepted cipher suites. Possible values are: TLS_DHE_DSS_WITH_AES_128_CBC_SHA, TLS_DHE_DSS_WITH_AES_128_CBC_SHA256, TLS_DHE_DSS_WITH_AES_256_CBC_SHA, TLS_DHE_DSS_WITH_AES_256_CBC_SHA256, TLS_DHE_RSA_WITH_AES_128_CBC_SHA, TLS_DHE_RSA_WITH_AES_128_GCM_SHA256, TLS_DHE_RSA_WITH_AES_256_CBC_SHA, TLS_DHE_RSA_WITH_AES_256_GCM_SHA384, TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA, TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256, TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256, TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA, TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384, TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384, TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA, TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256, TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA, TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384, TLS_RSA_WITH_3DES_EDE_CBC_SHA, TLS_RSA_WITH_AES_128_CBC_SHA, TLS_RSA_WITH_AES_128_CBC_SHA256, TLS_RSA_WITH_AES_128_GCM_SHA256, TLS_RSA_WITH_AES_256_CBC_SHA, TLS_RSA_WITH_AES_256_CBC_SHA256 and TLS_RSA_WITH_AES_256_GCM_SHA384.
    #     min_protocol_version = ""                                                                                     #(Optional) The minimal TLS version. Possible values are TLSv1_0, TLSv1_1 and TLSv1_2.
    #   }
    # }

    enable_http2 = true                                                                                               #(Optional) Is HTTP2 enabled on the application gateway resource? Defaults to false.

    # - 
    # - Probe
    # - 
    probe = {                                                                                                         #(Optional) One or more probe blocks
      dev_health_test_us = {
        host                                      = ""                                                                #(Optional) The Hostname used for this Probe. If the Application Gateway is configured for a single site, by default the Host name should be specified as ‘127.0.0.1’, unless otherwise configured in custom probe. Cannot be set if pick_host_name_from_backend_http_settings is set to true.
        interval                                  = "10"                                                              #(Required) The Interval between two consecutive probes in seconds. Possible values range from 1 second to a maximum of 86,400 seconds.
        name                                      = "dev-health-test-us"                                              #(Required) The Name of the Probe.
        protocol                                  = "Https"                                                           #(Required) The Protocol used for this Probe. Possible values are Http and Https.
        path                                      = "/api/health?source=ag"                                           #(Required) The Path used for this Probe.
        timeout                                   = "7"                                                               #(Required) The Timeout used for this Probe, which indicates when a probe becomes unhealthy. Possible values range from 1 second to a maximum of 86,400 seconds.
        unhealthy_threshold                       = "5"                                                               #(Required) The Unhealthy Threshold for this Probe, which indicates the amount of retries which should be attempted before a node is deemed unhealthy. Possible values are from 1 - 20 seconds.
        pick_host_name_from_backend_http_settings = true                                                              #(Optional) Whether the host header should be picked from the backend http settings. Defaults to false.
        match = {
          match_1 = {                                                                                                 #(Optional) A match block as defined above.
            body        = ""
            statusCodes = ["200-399"]
          }
        }
        minimum_servers                           = 0                                                                 #(Optional) The minimum number of servers that are always marked as healthy. Defaults to 0.      
      }                       
    }

    # - 
    # - SSL Certificate
    # - 
    ssl_certificate = {                                                                                                #(Optional) One or more ssl_certificate blocks
      test_us = {
        name                = "wildcard.test.com"                                                             #(Required) The Name of the SSL certificate that is unique within this Application Gateway
        key_vault_secret_id = "https://keyvault-test-dev.vault.azure.net/secrets/Test-Wildcard/sdfgwedfgtg345terfgedfg" #** Need KV ID                                                                        #(Optional) Secret Id of (base-64 encoded unencrypted pfx) Secret or Certificate object stored in Azure KeyVault. You need to enable soft delete for keyvault to use this feature. Required if data is not set.
      }  
    }

    # - 
    # - Identity
    # -     
    identity = {
      kv_identity = {
        type         = "UserAssigned"                                                                                   #(Required) Specifies the identity type of the App Service. Possible values are SystemAssigned (where Azure will generate a Service Principal for you), UserAssigned where you can specify the Service Principal IDs in the identity_ids field, and SystemAssigned, UserAssigned which assigns both a system managed identity as well as the specified user assigned identities. NOTE: When type is set to SystemAssigned, The assigned principal_id and tenant_id can be retrieved after the App Service has been created. More details are available below.
        identity_ids = ["/subscriptions/[AZURE SUBSCRIPTION]/resourceGroups/DEV-INF-Identity-ARG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/dev-app-test-ami"]                                                                                               #(Optional) Specifies a list of user managed identity ids to be assigned. Required if type is UserAssigned.
      }
    }

    # - 
    # - URL Path Map
    # - 
    url_path_map = {                                                                                                  #(Optional) One or more url_path_map blocks
      dev_path_us = {
        name                                = "dev-path-us"                                                      
        default_backend_address_pool_name   = "dev-brand"                                                            
        default_backend_http_settings_name  = "dev-https-brand-us"                                               

        path_rule = {                                                                                                 
          account = {      
            name                              = "Account"                                                              
            paths                             = ["/account*"]                                                            
            backend_address_pool_name         = "test-dev"                                                           
            backend_http_settings_name        = "dev-https-test"                                                     
          }                                                                                                
        }
      }           
    }

    # - 
    # - Autoscale Configurations
    # - 
    autoscale_configuration = {
      agw_2 = {
        min_capacity = 2                                                                                              #(Required) Minimum capacity for autoscaling. Accepted values are in the range 0 to 100.
        max_capacity = 10                                                                                             #(Optional) Maximum capacity for autoscaling. Accepted values are in the range 2 to 125. 
      }
    }

    # - 
    # - Rewrite Rule Set
    # - 
    # rewrite_rule_set = {}

    tags = {
      "service"  = "agw"
      "priority" = "primary"
    }
  }
}