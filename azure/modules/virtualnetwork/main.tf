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
# - Virtual Network
# -
resource "azurerm_virtual_network" "vnet1" {
  depends_on          =[azurerm_network_ddos_protection_plan.dpp1]
  for_each            = var.virtual_networks
  name                = "vnet-${each.value["name"]}-${var.environment}"                                                     #(Required) The name of the virtual network. Changing this forces a new resource to be created.
  location            = lookup(each.value, "location", null) == null ? data.azurerm_resource_group.rg.location : each.value["location"]
  resource_group_name = data.azurerm_resource_group.rg.name
  
  address_space       = each.value["address_space"]                                                                         #(Required) The address space that is used the virtual network. You can supply more than one address space.
  bgp_community       = lookup(each.value, "bgp_community", null)                                                           #(Optional) The BGP community attribute in format <as-number>:<community-value>.
  
  ddos_protection_plan {                                                                                                    #(Optional) A ddos_protection_plan block as documented below.
    id     = lookup(merge(data.azurerm_network_ddos_protection_plan.dpp1,azurerm_network_ddos_protection_plan.dpp1), each.value["ddos_protection_plan_key"])["id"] #(Required) The ID of DDoS Protection Plan.
    enable = each.value["enable"]                                                                                           #(Required) Enable/disable DDoS Protection Plan on Virtual Network.      
  }
  
  dns_servers          = lookup(each.value, "dns_servers", null)                                                            #(Optional) List of IP addresses of DNS servers

  tags = merge(data.azurerm_resource_group.rg.tags, lookup(each.value, "tags", []))
}

# - 
# - Subnets
# - 

resource "azurerm_subnet" "sub1" {
  depends_on           = [azurerm_virtual_network.vnet1]
  for_each             = var.subnets
  name                 = each.value["name"]
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = lookup(azurerm_virtual_network.vnet1, each.value["vnet_key"])["name"]     #(Required) The name of the virtual network to which to attach the subnet. Changing this forces a new resource to be created.
  
  address_prefixes     = lookup(each.value, "address_prefixes", null)                              #(Optional) The address prefixes to use for the subnet.
  #address_prefix       = lookup(each.value, "address_prefix", null)

  dynamic "delegation" {                                                                           #(Optional) One or more delegation blocks as defined below.  
    for_each = lookup(each.value, "delegation", [])
    content {
      name         = delegation.value["name"]                                                      #(Required) A name for this delegation.

      dynamic "service_delegation" {
        for_each = delegation.value["service_delegation"]
        content {
          name         = delegation.value["name"]                                                  #(Required) The name of service to delegate to. Possible values include Microsoft.ApiManagement/service, Microsoft.AzureCosmosDB/clusters, Microsoft.BareMetal/AzureVMware, Microsoft.BareMetal/CrayServers, Microsoft.Batch/batchAccounts, Microsoft.ContainerInstance/containerGroups, Microsoft.Databricks/workspaces, Microsoft.DBforMySQL/flexibleServers, Microsoft.DBforMySQL/serversv2, Microsoft.DBforPostgreSQL/flexibleServers, Microsoft.DBforPostgreSQL/serversv2, Microsoft.DBforPostgreSQL/singleServers, Microsoft.HardwareSecurityModules/dedicatedHSMs, Microsoft.Kusto/clusters, Microsoft.Logic/integrationServiceEnvironments, Microsoft.MachineLearningServices/workspaces, Microsoft.Netapp/volumes, Microsoft.Network/managedResolvers, Microsoft.PowerPlatform/vnetaccesslinks, Microsoft.ServiceFabricMesh/networks, Microsoft.Sql/managedInstances, Microsoft.Sql/servers, Microsoft.StreamAnalytics/streamingJobs, Microsoft.Synapse/workspaces, Microsoft.Web/hostingEnvironments, and Microsoft.Web/serverFarms.
          actions      = lookup(delegation.value, "actions", null)                                 #(Optional) A list of Actions which should be delegated. This list is specific to the service to delegate to. Possible values include Microsoft.Network/networkinterfaces/*, Microsoft.Network/virtualNetworks/subnets/action, Microsoft.Network/virtualNetworks/subnets/join/action, Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action and Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action.    
        }
      }
    }
  }

  enforce_private_link_endpoint_network_policies = lookup(each.value, "enforce_private_link_endpoint_network_policies", null) #(Optional) Enable or Disable network policies for the private link endpoint on the subnet. Default value is false. Conflicts with enforce_private_link_service_network_policies.  
  enforce_private_link_service_network_policies  = lookup(each.value, "enforce_private_link_service_network_policies", null)  #(Optional) Enable or Disable network policies for the private link service on the subnet. Default valule is false. Conflicts with enforce_private_link_endpoint_network_policies.  
  service_endpoints                              = lookup(each.value, "service_endpoints", null)                              #(Optional) The list of Service endpoints to associate with the subnet. Possible values include: Microsoft.AzureActiveDirectory, Microsoft.AzureCosmosDB, Microsoft.ContainerRegistry, Microsoft.EventHub, Microsoft.KeyVault, Microsoft.ServiceBus, Microsoft.Sql, Microsoft.Storage and Microsoft.Web.  
  service_endpoint_policy_ids                    = lookup(each.value, "service_endpoint_policy_ids", null)                    #(Optional) The list of IDs of Service Endpoint Policies to associate with the subnet.  
}

# -
# - Route Tables
# -
resource "azurerm_route_table" "rt1" {
  for_each            = var.route_tables
  name                = "rt-${each.value["name"]}-${var.environment}"
  location            = lookup(each.value, "location", null) == null ? data.azurerm_resource_group.rg.location : each.value["location"]
  resource_group_name = data.azurerm_resource_group.rg.name

  dynamic "route" {
    for_each                 = lookup(each.value, "route", null)
    content {
      name                   = route.value["name"]                                                                            #(Required) The name of the route.
      address_prefix         = route.value["address_prefix"]                                                                  #(Required) The destination CIDR to which the route applies, such as 10.1.0.0/16. Tags such as VirtualNetwork, AzureLoadBalancer or Internet can also be used.
      next_hop_type          = route.value["next_hop_type"]                                                                   #(Required) The type of Azure hop the packet should be sent to. Possible values are VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance and None.
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)                                            #(Optional) Contains the IP address packets should be forwarded to. Next hop values are only allowed in routes where the next hop type is VirtualAppliance.
    }
  }
  
  disable_bgp_route_propagation = lookup(each.value, "disable_bgp_route_propagation", null)                                   #(Optional) Boolean flag which controls propagation of routes learned by BGP on that route table. True means disable.

}

# -
# - Route Table Association
# -
resource "azurerm_subnet_route_table_association" "rta1" {
  for_each       = var.route_table_association
  subnet_id      = lookup(azurerm_subnet.sub1, each.value["subnet_key"])["id"]
  route_table_id = lookup(azurerm_route_table.rt1, each.value["route_table_key"])["id"]
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
# - Network Security Group Association
# - 
resource "azurerm_subnet_network_security_group_association" "nsga1" {
  for_each                  = var.network_security_group_association
  subnet_id                 = lookup(azurerm_subnet.sub1, each.value["subnet_key"])["id"]
  network_security_group_id = lookup(azurerm_network_security_group.nsg1, each.value["nsg_key"])["id"] 
}