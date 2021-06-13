# -
# - Data gathering
# -
data "azurerm_resource_group" "rg" {
  name = var.app_gateway_rg
}

data "azurerm_virtual_network" "vnet1" {
  for_each            = var.existing_virtual_networks
  name                = each.value["name"]
  resource_group_name = lookup(each.value, "resource_group_name", data.azurerm_resource_group.rg.name)  
}

data "azurerm_public_ip" "pip1" {
  for_each            = var.existing_public_ips
  name                = each.value["name"]
  resource_group_name = lookup(each.value, "resource_group_name", data.azurerm_resource_group.rg.name)  
}

# -
# - Virtual Network
# -
resource "azurerm_virtual_network" "vnet1" {
  for_each             = var.virtual_networks
  name                 = "vnet-${each.value["name"]}-${each.value["priority"]}-${var.environment}"                           #(Required) The name of the virtual network. Changing this forces a new resource to be created.
  resource_group_name  = data.azurerm_resource_group.rg.name                                                                 #(Required) The name of the resource group in which to create the virtual network.
  address_space        = each.value["address_space"]                                                                         #(Required) The address space that is used the virtual network. You can supply more than one address space.
  location             = var.app_gateway_location                                                                            #(Required) The location/region where the virtual network is created. Changing this forces a new resource to be created.
  bgp_community        = lookup(each.value, "bgp_community", null)                                                           #(Optional) The BGP community attribute in format <as-number>:<community-value>.
  dynamic "ddos_protection_plan" {                                                                                           #(Optional) A ddos_protection_plan block as documented below.
    for_each = lookup(each.value, "ddos_protection_plan", var.null_array)
    contecnt {
      id     = ddos_protection_plan.value["id"]                                                                              #(Required) The ID of DDoS Protection Plan.
      enable = ddos_protection_plan.value["enable"]                                                                          #(Required) Enable/disable DDoS Protection Plan on Virtual Network.      
    }
  
  dns_servers          = lookup(each.value, "dns_servers", null)                                                             #(Optional) List of IP addresses of DNS servers

  dynamic "subnet" {                                                                                                         #(Optional) Can be specified multiple times to define multiple subnets. Each subnet block supports fields documented below.
    for_each = lookup(each.value, "subnet", var.null_array)
    content {
      name           = subnet.value["name"]                                                                                  #(Required) The name of the subnet.
      address_prefix = subnet.value["address_prefix"]                                                                        #(Required) The address prefix to use for the subnet.
      security_group = lookup(subnet.value, "security_group", null)                                                          #(Optional) The Network Security Group to associate with the subnet. (Referenced by id, ie. azurerm_network_security_group.example.id)
  }

  tags = merge(data.azurerm_resource_group.rg.tags, lookup(each.value, "tags", null))
}

# -
# - Public IP
# -
resource "azurerm_public_ip" "pip1" {
  for_each                = var.public_ips
  name                    = "vnet-${each.value["name"]}-${each.value["priority"]}-${var.environment}"  #(Required) Specifies the name of the Public IP resource . Changing this forces a new resource to be created.
  resource_group_name     = data.azurerm_resource_group.rg.name                                        #(Required) The name of the resource group in which to create the public ip.
  location                = var.app_gateway_location                                                   #(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
  sku                     = lookup(each.value, "", null)                                               #(Optional) The SKU of the Public IP. Accepted values are Basic and Standard. Defaults to Basic.
  allocation_method       = each.value["allocation_method"]                                            #(Required) Defines the allocation method for this IP address. Possible values are Static or Dynamic.
  availability_zone       = lookup(each.value, "availability_zone", null)                              #(Optional) The availability zone to allocate the Public IP in. Possible values are Zone-Redundant, 1, 2, 3, and No-Zone. Defaults to Zone-Redundant.
  ip_version              = lookup(each.value, "ip_version", null)                                     #(Optional) The IP Version to use, IPv6 or IPv4.
  idle_timeout_in_minutes = lookup(each.value, "idle_timeout_in_minutes", null)                        #(Optional) Specifies the timeout for the TCP idle connection. The value can be set between 4 and 30 minutes.
  domain_name_label       = lookup(each.value, "domain_name_label", null)                              #(Optional) Label for the Domain Name. Will be used to make up the FQDN. If a domain name label is specified, an A DNS record is created for the public IP in the Microsoft Azure DNS system.
  reverse_fqdn            = lookup(each.value, "reverse_fqdn", null)                                   #(Optional) A fully qualified domain name that resolves to this public IP address. If the reverseFqdn is specified, then a PTR DNS record is created pointing from the IP address in the in-addr.arpa domain to the reverse FQDN.
  public_ip_prefix_id     = lookup(each.value, "public_ip_prefix_id", null)                            #(Optional) If specified then public IP address allocated will be provided from the public IP prefix resource.
  ip_tags                 = lookup(each.value, "ip_tags", null)                                        #(Optional) A mapping of IP tags to assign to the public IP.
  
  tags = merge(data.azurerm_resource_group.rg.tags, lookup(each.value, "tags", null))
}


# -
# - Application Gateway
# -

resource "azurerm_application_gateway" "agw1" {
  for_each            = var.app_gateways
  name                = "agw-${each.value["name"]}-${each.value["priority"]}-${var.environment}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.app_gateway_location

  # - 
  # - Backend Address Pool
  # - 
  dynamic "backend_address_pool" {                                                                                           #(Required) One or more backend_address_pool blocks
    for_each = lookup(each.value, "backend_address_pool", [])
    content {
      name         = backend_address_pool.value["name"]                                                                      #(Required) The name of the Backend Address Pool.
      fqdns        = lookup(backend_address_pool.value, "fqdns", null)                                                       #(Optional) A list of FQDN's which should be part of the Backend Address Pool.
      ip_addresses = lookup(backend_address_pool.value, "ip_addresses", null)                                                #(Optional) A list of IP Addresses which should be part of the Backend Address Pool.      
    }
  }

  # - 
  # - Backend Http Settings
  # - 
  dynamic "backend_http_settings" {                                                                                          #(Required) One or more backend_http_settings blocks
    for_each = lookup(each.value, "backend_http_settings", [])
    content {
      cookie_based_affinity               = backend_http_settings.value["cookie_based_affinity"]                             #(Required) Is Cookie-Based Affinity enabled? Possible values are Enabled and Disabled.
      affinity_cookie_name                = lookup(backend_http_settings.value, "affinity_cookie_name", null)                #(Optional) The name of the affinity cookie.
      name                                = backend_http_settings.value["name"]                                              #(Required) The name of the Backend HTTP Settings Collection.
      path                                = lookup(backend_http_settings.value, "path", null)                                #(Optional) The Path which should be used as a prefix for all HTTP requests.
      port                                = backend_http_settings.value["port"]                                              #(Required) The port which should be used for this Backend HTTP Settings Collection.
      probe_name                          = lookup(backend_http_settings.value, "probe_name", null)                          #(Optional) The name of an associated HTTP Probe.
      protocol                            = backend_http_settings.value["protocol"]                                          #(Required) The Protocol which should be used. Possible values are Http and Https.
      request_timeout                     = backend_http_settings.value["request_timeout"]                                   #(Required) The request timeout in seconds, which must be between 1 and 86400 seconds.
      host_name                           = lookup(backend_http_settings.value, "host_name", null)                           #(Optional) Host header to be sent to the backend servers. Cannot be set if pick_host_name_from_backend_address is set to true.
      pick_host_name_from_backend_address = lookup(backend_http_settings.value, "pick_host_name_from_backend_address", null) #(Optional) Whether host header should be picked from the host name of the backend server. Defaults to false.

      dynamic "authentication_certificate" {                                                                                 #(Optional) One or more authentication_certificate blocks.
        for_each = lookup(each.value, "authentication_certificate", var.null_array)
        content {
          name = authentication_certificate.value["name"]                                                                    #(Required) The Name of the Authentication Certificate to use.
          data = authentication_certificate.value["data"]                                                                    #(Required) The contents of the Authentication Certificate which should be used.        
        }
 
      trusted_root_certificate_names = lookup(backend_http_settings.value, "trusted_root_certificate_names", null)           #(Optional) A list of trusted_root_certificate names.

      dynamic "connection_draining" {                                                                                        #(Optional) A connection_draining block
        for_each = lookup(each.value, "connection_draining", var.null_array)
        content {
          enabled           = connection_draining.value["enabled"]                                                           #(Required) If connection draining is enabled or not.
          drain_timeout_sec = connection_draining.value["drain_timeout_sec"]                                                 #(Required) The number of seconds connection draining is active. Acceptable values are from 1 second to 3600 seconds.        
        }      
    }
  }

  # - 
  # - Frontend Ip Configurations
  # - 
  dynamic "frontend_ip_configuration" {                                                                                      #(Required) One or more frontend_ip_configuration blocks
    for_each = lookup(each.value, "frontend_ip_configuration", [])
    content {
      name                          = frontend_ip_configuration.value["name"]                                                #(Required) The name of the Frontend IP Configuration.
      subnet_id                     = lookup(frontend_ip_configuration.value, "subnet_id", null)                             #(Optional) The ID of the Subnet.
      private_ip_address            = lookup(frontend_ip_configuration.value, "private_ip_address", null)                    #(Optional) The Private IP Address to use for the Application Gateway.
      public_ip_address_id          = lookup(merge(azurerm_public_ip.pip1, data.azurerm_public_ip.pip1), each.value["public_ip_key"])["id"] #(Optional) The ID of a Public IP Address which the Application Gateway should use. The allocation method for the Public IP Address depends on the sku of this Application Gateway. Please refer to the Azure documentation for public IP addresses for details.
      private_ip_address_allocation = lookup(frontend_ip_configuration.value, "private_ip_address_allocation", null)         #(Optional) The Allocation Method for the Private IP Address. Possible values are Dynamic and Static.      
    }
  }

  # - 
  # - Frontend Port
  # - 
  dynamic "frontend_port" {                                                                                                  #(Required) One or more frontend_port blocks as defined below.
    for_each = lookup(each.value, "frontend_port", [])
    content {
      name = frontend_port.value["name"]                                                                                     #(Required) The name of the Frontend Port.
      port = frontend_port.value["port"]                                                                                     #(Required) The port used for this Frontend Port.      
    }
  }

  # - 
  # - Gateway Ip Configurations
  # - 
  dynamic "gateway_ip_configuration" {                                                                                       #(Required) One or more gateway_ip_configuration blocks
    for_each = lookup(each.value, "gateway_ip_configuration", [])
    content {
      name      = gateway_ip_configuration.value["name"]                                                                     #(Required) The Name of this Gateway IP Configuration.
      subnet_id = lookup(merge(azurerm_virtual_network.vnet1, data.azurerm_virtual_network.vnet1), each.value["vnet_key"])["subnet"]["subnet_key"]["id"] #(Required) The ID of the Subnet which the Application Gateway should be connected to.      
    }
  }

  # - 
  # - Http Listeners
  # - 
  dynamic "http_listener" {                                                                                                  #(Required) One or more http_listener blocks
    for_each = lookup(each.value, "http_listener", [])
    content {
      name                           = http_listener.value["name"]                                                           #(Required) The Name of the HTTP Listener.
      frontend_ip_configuration_name = http_listener.value["frontend_ip_configuration_name"]                                 #(Required) The Name of the Frontend IP Configuration used for this HTTP Listener.
      frontend_port_name             = http_listener.value["frontend_port_name"]                                             #(Required) The Name of the Frontend Port use for this HTTP Listener.
      host_name                      = lookup(http_listener.value, "host_name", null)                                        #(Optional) The Hostname which should be used for this HTTP Listener. Setting this value changes Listener Type to 'Multi site'.
      host_names                     = lookup(http_listener.value, "host_names", null)                                       #(Optional) A list of Hostname(s) should be used for this HTTP Listener. It allows special wildcard characters.
      protocol                       = http_listener.value["protocol"]                                                       #(Required) The Protocol to use for this HTTP Listener. Possible values are Http and Https.
      require_sni                    = lookup(http_listener.value, "require_sni", null)                                      #(Optional) Should Server Name Indication be Required? Defaults to false.
      ssl_certificate_name           = lookup(http_listener.value, "ssl_certificate_name", null)                             #(Optional) The name of the associated SSL Certificate which should be used for this HTTP Listener.
      custom_error_configuration     = lookup(http_listener.value, "custom_error_configuration", null)                       #(Optional) One or more custom_error_configuration blocks as defined below.
      firewall_policy_id             = lookup(http_listener.value, "firewall_policy_id", null)                               #(Optional) The ID of the Web Application Firewall Policy which should be used as a HTTP Listener.
    }
  }

  # - 
  # - Identity Configuration
  # - 
  dynamic "identity" {                                                                                                       #(Optional) A identity block.
    for_each = lookup(each.value, "identity", var.null_array)
    content {
      type         = lookup(identity.value, "type", null)                                                                    #(Required) Specifies the identity type of the App Service. Possible values are SystemAssigned (where Azure will generate a Service Principal for you), UserAssigned where you can specify the Service Principal IDs in the identity_ids field, and SystemAssigned, UserAssigned which assigns both a system managed identity as well as the specified user assigned identities. NOTE: When type is set to SystemAssigned, The assigned principal_id and tenant_id can be retrieved after the App Service has been created. More details are available below.
      identity_ids = lookup(identity.value, "identity_ids", null)                                                            #(Optional) Specifies a list of user managed identity ids to be assigned. Required if type is UserAssigned.
    }
  }

  # - 
  # - Request Routing Rule
  # - 
  dynamic "request_routing_rule" {                                                                                          #(Required) One or more request_routing_rule blocks
    for_each = lookup(each.value, "request_routing_rule", [])
    content {
      name                        = request_routing_rule.value["name"]                                                      #(Required) The Name of this Request Routing Rule.
      rule_type                   = request_routing_rule.value["rule_type"]                                                 #(Required) The Type of Routing that should be used for this Rule. Possible values are Basic and PathBasedRouting.
      http_listener_name          = request_routing_rule.value["http_listener_name"]                                        #(Required) The Name of the HTTP Listener which should be used for this Routing Rule.
      backend_address_pool_name   = lookup(request_routing_rule.value, "backend_address_pool_name", null)                   #(Optional) The Name of the Backend Address Pool which should be used for this Routing Rule. Cannot be set if redirect_configuration_name is set.
      backend_http_settings_name  = lookup(request_routing_rule.value, "backend_http_settings_name", null)                  #(Optional) The Name of the Backend HTTP Settings Collection which should be used for this Routing Rule. Cannot be set if redirect_configuration_name is set.
      redirect_configuration_name = lookup(request_routing_rule.value, "redirect_configuration_name", null)                 #(Optional) The Name of the Redirect Configuration which should be used for this Routing Rule. Cannot be set if either backend_address_pool_name or backend_http_settings_name is set.
      rewrite_rule_set_name       = lookup(request_routing_rule.value, "rewrite_rule_set_name", null)                       #(Optional) The Name of the Rewrite Rule Set which should be used for this Routing Rule. Only valid for v2 SKUs.
      url_path_map_name           = lookup(request_routing_rule.value, "url_path_map_name", null)                           #(Optional) The Name of the URL Path Map which should be associated with this Routing Rule.
    }
  }

  # - 
  # - Sku
  # - 
  dynamic "sku" {                                                                                                           #(Required) A sku block
    for_each = lookup(each.value, "sku", [])
    content {
      name     = sku.value["name"]                                                                                          #(Required) The Name of the SKU to use for this Application Gateway. Possible values are Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2.
      tier     = sku.value["tier"]                                                                                          #(Required) The Tier of the SKU to use for this Application Gateway. Possible values are Standard, Standard_v2, WAF and WAF_v2.
      capacity = sku.value["capacity"]                                                                                      #(Required) The Capacity of the SKU to use for this Application Gateway. When using a V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU. This property is optional if autoscale_configuration is set.      
    }
  }

zones = lookup(each.value, "zones", null)                                                                                   #(Optional) A collection of availability zones to spread the Application Gateway over.

  # - 
  # - Authentication Certificate
  # - 
  dynamic "authentication_certificate" {                                                                                    #(Optional) One or more authentication_certificate blocks
    for_each = lookup(each.value, "authentication_certificate", var.null_array)
    content {
      name = authentication_certificate.value["name"]                                                                       #(Required) The Name of the Authentication Certificate to use.
      data = authentication_certificate.value["data"]                                                                       #(Required) The contents of the Authentication Certificate which should be used.      
    }
  }

  # - 
  # - Trusted Root Certificates
  # - 
  dynamic "trusted_root_certificate" {                                                                                      #(Optional) One or more trusted_root_certificate blocks
    for_each = lookup(each.value, "trusted_root_certificate", var.null_array)
    content {
      name = trusted_root_certificate.value["name"]                                                                         #(Required) The Name of the Trusted Root Certificate to use.
      data = trusted_root_certificate.value["data"]                                                                         #(Required) The contents of the Trusted Root Certificate which should be used.      
    }
  }

  # - 
  # - SSL Policy
  # - 
  dynamic "ssl_policy" {                                                                                                    #(Optional) a ssl policy block
    for_each = lookup(each.value, "ssl_policy", var.null_array)
    content {
      disabled_protocols   = lookup(ssl_policy.value, "disabled_protocols", null)                                           #(Optional) A list of SSL Protocols which should be disabled on this Application Gateway. Possible values are TLSv1_0, TLSv1_1 and TLSv1_2.
      policy_type          = lookup(ssl_policy.value, "policy_type", null)                                                  #(Optional) The Type of the Policy. Possible values are Predefined and Custom.
      policy_name          = lookup(ssl_policy.value, "policy_name", null)                                                  #(Optional) The Name of the Policy e.g AppGwSslPolicy20170401S. Required if policy_type is set to Predefined. Possible values can change over time and are published here https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-ssl-policy-overview. Not compatible with disabled_protocols.
      cipher_suites        = lookup(ssl_policy.value, "cipher_suites", null)                                                #(Optional) A List of accepted cipher suites. Possible values are: TLS_DHE_DSS_WITH_AES_128_CBC_SHA, TLS_DHE_DSS_WITH_AES_128_CBC_SHA256, TLS_DHE_DSS_WITH_AES_256_CBC_SHA, TLS_DHE_DSS_WITH_AES_256_CBC_SHA256, TLS_DHE_RSA_WITH_AES_128_CBC_SHA, TLS_DHE_RSA_WITH_AES_128_GCM_SHA256, TLS_DHE_RSA_WITH_AES_256_CBC_SHA, TLS_DHE_RSA_WITH_AES_256_GCM_SHA384, TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA, TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256, TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256, TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA, TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384, TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384, TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA, TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256, TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA, TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384, TLS_RSA_WITH_3DES_EDE_CBC_SHA, TLS_RSA_WITH_AES_128_CBC_SHA, TLS_RSA_WITH_AES_128_CBC_SHA256, TLS_RSA_WITH_AES_128_GCM_SHA256, TLS_RSA_WITH_AES_256_CBC_SHA, TLS_RSA_WITH_AES_256_CBC_SHA256 and TLS_RSA_WITH_AES_256_GCM_SHA384.
      min_protocol_version = lookup(ssl_policy.value, "min_protocol_version", null)                                         #(Optional) The minimal TLS version. Possible values are TLSv1_0, TLSv1_1 and TLSv1_2.
    }
  }

enable_http2 = lookup(each.value, "enable_http2", null)                                                                     #(Optional) Is HTTP2 enabled on the application gateway resource? Defaults to false.

  # - 
  # - Probe
  # - 
  dynamic "probe" {                                                                                                         #(Optional) One or more probe blocks
    for_each = lookup(each.value, "probe", var.null_array)
    content {
      host                                      = lookup(probe.value, "host", null)                                         #(Optional) The Hostname used for this Probe. If the Application Gateway is configured for a single site, by default the Host name should be specified as ‘127.0.0.1’, unless otherwise configured in custom probe. Cannot be set if pick_host_name_from_backend_http_settings is set to true.
      interval                                  = probe.value["interval"]                                                   #(Required) The Interval between two consecutive probes in seconds. Possible values range from 1 second to a maximum of 86,400 seconds.
      name                                      = probe.value["name"]                                                       #(Required) The Name of the Probe.
      protocol                                  = probe.value["protocol"]                                                   #(Required) The Protocol used for this Probe. Possible values are Http and Https.
      path                                      = probe.value["path"]                                                       #(Required) The Path used for this Probe.
      timeout                                   = probe.value["timeout"]                                                    #(Required) The Timeout used for this Probe, which indicates when a probe becomes unhealthy. Possible values range from 1 second to a maximum of 86,400 seconds.
      unhealthy_threshold                       = probe.value["unhealthy"]                                                  #(Required) The Unhealthy Threshold for this Probe, which indicates the amount of retries which should be attempted before a node is deemed unhealthy. Possible values are from 1 - 20 seconds.
      port                                      = lookup(probe.value, "port", null)                                         #(Optional) Custom port which will be used for probing the backend servers. The valid value ranges from 1 to 65535. In case not set, port from http settings will be used. This property is valid for Standard_v2 and WAF_v2 only.
      pick_host_name_from_backend_http_settings = lookup(probe.value, "pick_host_name_from_backend_http_settings", null)    #(Optional) Whether the host header should be picked from the backend http settings. Defaults to false.
      match                                     = lookup(probe.value, "match", null)                                        #(Optional) A match block as defined above.
      minimum_servers                           = lookup(probe.value, "minimum_servers", null)                              #(Optional) The minimum number of servers that are always marked as healthy. Defaults to 0.      
    }
  }

  # - 
  # - SSL Certificate
  # - 
  dynamic "ssl_certificate" {                                                                                               #(Optional) One or more ssl_certificate blocks
    for_each = lookup(each.value, "ssl_certificate", var.null_array)
    content {
      name                = ssl_certificate.value["name"]                                                                   #(Required) The Name of the SSL certificate that is unique within this Application Gateway
      data                = lookup(ssl_certificate.value, "data", null)                                                     #(Optional) PFX certificate. Required if key_vault_secret_id is not set.
      password            = lookup(ssl_certificate.value, "password", null)                                                 #(Optional) Password for the pfx file specified in data. Required if data is set.
      key_vault_secret_id = lookup(ssl_certificate.value, "key_vault_secret_id", null)                                      #(Optional) Secret Id of (base-64 encoded unencrypted pfx) Secret or Certificate object stored in Azure KeyVault. You need to enable soft delete for keyvault to use this feature. Required if data is not set.
    }
  }

  # - 
  # - URL Path Map
  # - 
  dynamic "url_path_map" {                                                                                                  #(Optional) One or more url_path_map blocks
    for_each = lookup(each.value, "url_path_map", var.null_array)
    content {
      name                                = url_path_map.value["name"]                                                      #(Required) The Name of the URL Path Map.
      default_backend_address_pool_name   = lookup(url_path_map.value, "default_backend_address_pool_name", null)           #(Optional) The Name of the Default Backend Address Pool which should be used for this URL Path Map. Cannot be set if default_redirect_configuration_name is set.
      default_backend_http_settings_name  = lookup(url_path_map.value, "default_backend_http_settings_name", null)          #(Optional) The Name of the Default Backend HTTP Settings Collection which should be used for this URL Path Map. Cannot be set if default_redirect_configuration_name is set.
      default_redirect_configuration_name = lookup(url_path_map.value, "default_redirect_configuration_name", null)         #(Optional) The Name of the Default Redirect Configuration which should be used for this URL Path Map. Cannot be set if either default_backend_address_pool_name or default_backend_http_settings_name is set.
      default_rewrite_rule_set_name       = lookup(url_path_map.value, "default_rewrite_rule_set_name", null)               #(Optional) The Name of the Default Rewrite Rule Set which should be used for this URL Path Map. Only valid for v2 SKUs.

      dynamic "path_rule" {                                                                                                 #(Required) One or more path_rule blocks
      for_each = lookup(each.value, "path_rule", [])
      content {      
        name                        = path_rule.value["name"]                                                               #(Required) The Name of the Path Rule.
        paths                       = path_rule.value["paths"]                                                              #(Required) A list of Paths used in this Path Rule.
        backend_address_pool_name   = lookup(path_rule.value, "backend_address_pool_name", null)                            #(Optional) The Name of the Backend Address Pool to use for this Path Rule. Cannot be set if redirect_configuration_name is set.
        backend_http_settings_name  = lookup(path_rule.value, "backend_http_settings_name", null)                           #(Optional) The Name of the Backend HTTP Settings Collection to use for this Path Rule. Cannot be set if redirect_configuration_name is set.
        redirect_configuration_name = lookup(path_rule.value, "redirect_configuration_name", null)                          #(Optional) The Name of a Redirect Configuration to use for this Path Rule. Cannot be set if backend_address_pool_name or backend_http_settings_name is set.
        rewrite_rule_set_name       = lookup(path_rule.value, "rewrite_rule_set_name", null)                                #(Optional) The Name of the Rewrite Rule Set which should be used for this URL Path Map. Only valid for v2 SKUs.
        firewall_policy_id          = lookup(path_rule.value, "firewall_policy_id", null)                                   #(Optional) The ID of the Web Application Firewall Policy which should be used as a HTTP Listener.      
      }
    }
  }

  # - 
  # - WAF Configuration
  # - 
  dynamic "waf_configuration" {                                                                                             #(Optional) A waf_configuration block
    for_each = lookup(each.value, "waf_configuration", var.null_array)
    content {
      enabled          = waf_configuration.value["enabled"]                                                                 #(Required) Is the Web Application Firewall be enabled?
      firewall_mode    = waf_configuration.value["firewall_mode"]                                                           #(Required) The Web Application Firewall Mode. Possible values are Detection and Prevention.
      rule_set_type    = waf_configuration.value["rule_set_type"]                                                           #(Required) The Type of the Rule Set used for this Web Application Firewall. Currently, only OWASP is supported.
      rule_set_version = waf_configuration.value["rule_set_version"]                                                        #(Required) The Version of the Rule Set used for this Web Application Firewall. Possible values are 2.2.9, 3.0, and 3.1.
      
      dynamic "disabled_rule_group" {                                                                                       #(Optional) one or more disabled_rule_group blocks
      for_each = lookup(each.value, "disabled_rule_group", var.null_array)
      contect {
        rule_group_name = disabled_rule_group.value["rule_group_name"]                                                      #(Required) The rule group where specific rules should be disabled. Accepted values are: crs_20_protocol_violations, crs_21_protocol_anomalies, crs_23_request_limits, crs_30_http_policy, crs_35_bad_robots, crs_40_generic_attacks, crs_41_sql_injection_attacks, crs_41_xss_attacks, crs_42_tight_security, crs_45_trojans, General, REQUEST-911-METHOD-ENFORCEMENT, REQUEST-913-SCANNER-DETECTION, REQUEST-920-PROTOCOL-ENFORCEMENT, REQUEST-921-PROTOCOL-ATTACK, REQUEST-930-APPLICATION-ATTACK-LFI, REQUEST-931-APPLICATION-ATTACK-RFI, REQUEST-932-APPLICATION-ATTACK-RCE, REQUEST-933-APPLICATION-ATTACK-PHP, REQUEST-941-APPLICATION-ATTACK-XSS, REQUEST-942-APPLICATION-ATTACK-SQLI, REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION
        rules           = lookup(disabled_rule_group.value, "rules", null)                                                  #(Optional) A list of rules which should be disabled in that group. Disables all rules in the specified group if rules is not specified.        
      }  

      file_upload_limit_mb     = lookup(waf_configuration.value, "file_upload_limit_mb", null)                              #(Optional) The File Upload Limit in MB. Accepted values are in the range 1MB to 750MB for the WAF_v2 SKU, and 1MB to 500MB for all other SKUs. Defaults to 100MB.
      request_body_check       = lookup(waf_configuration.value, "request_body_check", null)                                #(Optional) Is Request Body Inspection enabled? Defaults to true.
      max_request_body_size_kb = lookup(waf_configuration.value, "max_request_body_size_kb", null)                          #(Optional) The Maximum Request Body Size in KB. Accepted values are in the range 1KB to 128KB. Defaults to 128KB.
      
      dynamic "exclusion" {                                                                                                 #(Optional) one or more exclusion blocks      
      for_each = lookup(each.value, "exclusion", var.null_array)
      contect {
        match_variable          = exclusion.value["match_variable"]                                                         #(Required) Match variable of the exclusion rule to exclude header, cookie or GET arguments. Possible values are RequestHeaderNames, RequestArgNames and RequestCookieNames
        selector_match_operator = lookup(exclusion.value, "selector_match_operator", null)                                  #(Optional) Operator which will be used to search in the variable content. Possible values are Equals, StartsWith, EndsWith, Contains. If empty will exclude all traffic on this match_variable
        selector                = lookup(exclusion.value, "selector", null)                                                 #(Optional) String value which will be used for the filter operation. If empty will exclude all traffic on this match_variable
      }  
    }
  }

  # - 
  # - Custom Error Configuration
  # - 
  dynamic "custom_error_configuration" {                                                                                    #(Optional) One or more custom_error_configuration blocks
    for_each = lookup(each.value, "custom_error_configuration", var.null_array)
    content {
      status_code           = custom_error_configuration.value["status_code"]                                               #(Required) Status code of the application gateway customer error. Possible values are HttpStatus403 and HttpStatus502
      custom_error_page_url = custom_error_configuration.value["custom_error_page_url"]                                     #(Required) Error page URL of the application gateway customer error.      
    }
  }

firewall_policy_id = lookup(each.value, "firewall_policy_id", null)                                                         #(Optional) The ID of the Web Application Firewall Policy.

  # - 
  # - Redirect Configuration
  # - 
  dynamic "redirect_configuration" {                                                                                        #(Optional) A redirect_configuration block
    for_each = lookup(each.value, "redirect_configuration", var.null_array)
    content {
      name                 = redirect_configuration.value["name"]                                                           #(Required) Unique name of the redirect configuration block
      redirect_type        = redirect_configuration.value["redirect_type"]                                                  #(Required) The type of redirect. Possible values are Permanent, Temporary, Found and SeeOther
      target_listener_name = lookup(redirect_configuration.value, "target_listener_name", null)                             #(Optional) The name of the listener to redirect to. Cannot be set if target_url is set.
      target_url           = lookup(redirect_configuration.value, "target_url", null)                                       #(Optional) The Url to redirect the request to. Cannot be set if target_listener_name is set.
      include_path         = lookup(redirect_configuration.value, "include_path", null)                                     #(Optional) Whether or not to include the path in the redirected Url. Defaults to false
      include_query_string = lookup(redirect_configuration.value, "include_query_string", null)                             #(Optional) Whether or not to include the query string in the redirected Url. Default to false      
    }
  }

  # - 
  # - Autoscale Configurations
  # - 
  dynamic "autoscale_configuration" {                                                                                       #(Optional) A autoscale_configuration block as defined below.
    for_each = lookup(each.value, "autoscale_configuration", var.null_array)
    content {
      min_capacity = autoscale_configuration.value["min_capacity"]                                                          #(Required) Minimum capacity for autoscaling. Accepted values are in the range 0 to 100.
      max_capacity = lookup(autoscale_configuration, "max_capacity", null)                                                  #(Optional) Maximum capacity for autoscaling. Accepted values are in the range 2 to 125.      
    }
  }

  # - 
  # - Rewrite Rule Set
  # - 
  dynamic "rewrite_rule_set" {                                                                                              #(Optional) One or more rewrite_rule_set blocks as defined below. Only valid for v2 SKUs.
    for_each = lookup(each.value, "rewrite_rule_set", var.null_array)
    content {
      name         = rewrite_rule_set.value["name"]                                                                         #(Required) Unique name of the rewrite rule set block
      rewrite_rule = rewrite_rule_set.value["rewrite_rule"]                                                                 #(Required) One or more rewrite_rule blocks as defined above.      
    }
  }

  tags = merge(data.azurerm_resource_group.rg.tags, lookup(each.value, "tags", null))
}