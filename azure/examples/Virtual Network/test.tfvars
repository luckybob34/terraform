# - 
# - General
# -
location            = "East US 2"
resource_group_name = "test-network-rg"
resource_group_lock = "rg-lock"
environment         = "test"

# - 
# - Resource Tags
# -
resource_tags = {
  "environement" = "test"
}

# -
# - DDoS Protection Plans
# - 
ddos_protection_plans = {
  ddos1 = {
    name = "main-ddos-plan"
    tags = {
      "service" = "ddos"
    }    
  }
}

# -
# - Network Security Groups
# -
network_security_groups = {
  nsg1 = {
    name = "nsg1"
    security_rule = [
      {
        name                       = "test123"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"        
      }
    ]
    tags = {
     "service" = "nsg"    
    } 
  }
}

# -
# - Virtual Networks
# -
virtual_networks = {
  vnet1 = {
    name                     = "test"
    address_space            = ["10.0.0.0/16"]
    dns_servers              = ["10.0.0.4", "10.0.0.5"]

    # DDoS Protection Plan
    ddos_prtections_plan_key = "ddos1"
    enabled                  = true

    subnet = {
      subnet_1 = {
        name                   = "subnet1"
        address_prefix         = "10.0.1.0/24"
      }
      subnet_2 = {
        name                   = "subnet2"
        address_prefix         = "10.0.2.0/24"
      }
      subnet_3 = {
        name                   = "subnet3"
        address_prefix         = "10.0.3.0/24"
        nsg_key                = "nsg1"
      }
    }
    tags = {
     "service" = "vnet"    
    }     
  }
}
