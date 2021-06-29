# -
# - Data gathering
# -

# Lookup Resource Group
data "azurerm_resource_group" "rg" {
  name = var.network_rg
}

# Lookup existing DDoS Plans
data "azurerm_network_ddos_protection_plan" "dpp1" {
  for_each            = var.existing_ddos_protection_plans
  name                = each.value["name"] 
  resource_group_name = each.value["resource_group_name"]
}

# Lookup existing Network Security Groups
data "azurerm_network_security_group" "nsg1" {
  for_each            = var.existing_network_security_groups
  name                = each.value["name"]
  resource_group_name = each.value["resource_group_name"] 
}

# -
# - DDoS Plan
# -
resource "azurerm_network_ddos_protection_plan" "dpp1" {
  for_each            = var.ddos_protection_plans
  name                = "dpp-${each.value["name"]}-${var.environment}"
  location            = lookup(each.value, "location", null) == null ? data.azurerm_resource_group.rg.location : each.value["location"]
  resource_group_name = data.azurerm_resource_group.rg.name

  tags                = merge(data.azurerm_resource_group.rg.tags, lookup(each.value, "tags", []))
}

# -
# - Network Security Group
# - 
resource "azurerm_network_security_group" "nsg1" {
  for_each            = var.network_security_groups
  name                = "nsg-${each.value["name"]}-${var.environment}"                                                      #(Required) Specifies the name of the network security group. Changing this forces a new resource to be created.
  location            = lookup(each.value, "location", null) == null ? data.azurerm_resource_group.rg.location : each.value["location"]
  resource_group_name = data.azurerm_resource_group.rg.name


  dynamic "security_rule" {
    for_each = lookup(each.value, "security_rule", null)
    content {
      name                                       = "sr-${security_rule.value["name"]}-${var.environment}"                          #(Required) The name of the security rule.
      description                                = lookup(security_rule.value, "description", null)                                #(Optional) A description for this rule. Restricted to 140 characters.
      protocol                                   = security_rule.value["protocol"]                                                 #(Required) Network protocol this rule applies to. Can be Tcp, Udp, Icmp, or * to match all.
      source_port_range                          = lookup(security_rule.value, "source_port_range", null)                          #(Optional) Source Port or Range. Integer or range between 0 and 65535 or * to match any. This is required if source_port_ranges is not specified.
      source_port_ranges                         = lookup(security_rule.value, "source_port_ranges", null)                         #(Optional) List of source ports or port ranges. This is required if source_port_range is not specified.
      destination_port_range                     = lookup(security_rule.value, "destination_port_range", null)                     #(Optional) Destination Port or Range. Integer or range between 0 and 65535 or * to match any. This is required if destination_port_ranges is not specified.
      destination_port_ranges                    = lookup(security_rule.value, "destination_port_ranges", null)                    #(Optional) List of destination ports or port ranges. This is required if destination_port_range is not specified.
      source_address_prefix                      = lookup(security_rule.value, "source_address_prefix", null)                      #(Optional) CIDR or source IP range or * to match any IP. Tags such as ‘VirtualNetwork’, ‘AzureLoadBalancer’ and ‘Internet’ can also be used. This is required if source_address_prefixes is not specified.
      source_address_prefixes                    = lookup(security_rule.value, "source_address_prefixes", null)                    #(Optional) List of source address prefixes. Tags may not be used. This is required if source_address_prefix is not specified.
      source_application_security_group_ids      = lookup(security_rule.value, "source_application_security_group_ids", null)      #(Optional) A List of source Application Security Group ID's
      destination_address_prefix                 = lookup(security_rule.value, "destination_address_prefix", null)                 #(Optional) CIDR or destination IP range or * to match any IP. Tags such as ‘VirtualNetwork’, ‘AzureLoadBalancer’ and ‘Internet’ can also be used. This is required if destination_address_prefixes is not specified.
      destination_address_prefixes               = lookup(security_rule.value, "destination_address_prefixes", null)               #(Optional) List of destination address prefixes. Tags may not be used. This is required if destination_address_prefix is not specified.
      destination_application_security_group_ids = lookup(security_rule.value, "destination_application_security_group_ids", null) #(Optional) A List of destination Application Security Group ID's
      access                                     = security_rule.value["access"]                                                   #(Required) Specifies whether network traffic is allowed or denied. Possible values are Allow and Deny.
      priority                                   = security_rule.value["priority"]                                                 #(Required) Specifies the priority of the rule. The value can be between 100 and 4096. The priority number must be unique for each rule in the collection. The lower the priority number, the higher the priority of the rule.
      direction                                  = security_rule.value["direction"]                                                #(Required) The direction specifies if rule will be evaluated on incoming or outgoing traffic. Possible values are Inbound and Outbound.
    }
  }

  tags = merge(data.azurerm_resource_group.rg.tags, lookup(each.value, "tags", []))
}

# -
# - Virtual Network
# -
resource "azurerm_virtual_network" "vnet1" {
  for_each            = var.virtual_networks
  name                = "vnet-${each.value["name"]}-${var.environment}"                                                     #(Required) The name of the virtual network. Changing this forces a new resource to be created.
  location            = lookup(each.value, "location", null) == null ? data.azurerm_resource_group.rg.location : each.value["location"]
  resource_group_name = data.azurerm_resource_group.rg.name
  
  address_space       = each.value["address_space"]                                                                         #(Required) The address space that is used the virtual network. You can supply more than one address space.
  bgp_community       = lookup(each.value, "bgp_community", null)                                                           #(Optional) The BGP community attribute in format <as-number>:<community-value>.
  
  dynamic "ddos_protection_plan" {                                                                                           #(Optional) A ddos_protection_plan block as documented below.
    for_each = lookup(each.value, "ddos_protection_plan", var.null_array)
    content {
      id     = lookup(merge(data.azurerm_ddos_prtection_plan.dpp1,azurerm_ddos_prtection_plan.dpp1), ddos_protection_plan.value["ddos_protection_plan_key"])["id"] #(Required) The ID of DDoS Protection Plan.
      enable = ddos_protection_plan.value["enable"]                                                                          #(Required) Enable/disable DDoS Protection Plan on Virtual Network.      
    }
  }
  
  dns_servers          = lookup(each.value, "dns_servers", null)                                                             #(Optional) List of IP addresses of DNS servers

  dynamic "subnet" {                                                                                                         #(Optional) Can be specified multiple times to define multiple subnets. Each subnet block supports fields documented below.
    for_each = lookup(each.value, "subnet", var.null_array)
    content {
      name           = subnet.value["name"]                                                                                  #(Required) The name of the subnet.
      address_prefix = subnet.value["address_prefix"]                                                                        #(Required) The address prefix to use for the subnet.
      security_group = lookup(subnet.value, "nsg_key", null) != null ? lookup(merge(data.azurerm_network_security_group.nsg1, azurerm_network_security_group.nsg1), subnet.value["nsg_key"])["id"] : null                                                         #(Optional) The Network Security Group to associate with the subnet. (Referenced by id, ie. azurerm_network_security_group.example.id)
    }
  }

  tags = merge(data.azurerm_resource_group.rg.tags, lookup(each.value, "tags", []))
}