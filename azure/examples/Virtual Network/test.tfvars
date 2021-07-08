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
  ddos2 = {
    name = "main-ddos2-plan"
    location = "Central US"
    tags = {
      "service" = "ddos"
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
    ddos_protection_plan = {
      ddos = {
        ddos_protection_plan_key = "ddos1"
        enable                   = true
      }
    }

    tags = {
     "service" = "vnet"    
    }     
  }  
  vnet2 = {
    name                     = "test2"
    location                 = "Central US"
    address_space            = ["10.0.0.0/16"]
    dns_servers              = ["10.0.0.4", "10.0.0.5"]

    # DDoS Protection Plan
    ddos_protection_plan = {
      ddos = {
        ddos_protection_plan_key = "ddos2"
        enable                   = true
      }
    }

    tags = {
     "service" = "vnet"    
    }     
  }  
}

# -
# - Network Security Groups
# -
network_security_groups = {
  nsg_1 = {
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
  nsg_2 = {
    name = "nsg2"
    location    = "Central US"
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
# - Route Tables
# - 
route_tables = {
  rt_1 = {
    name = "rt1"
    route = {
      route_1 = {
        name           = "route1"
        address_prefix = "10.1.0.0/16"
        next_hop_type  = "vnetlocal"
      }     
    }
  } 
  rt_2 = {
    name = "rt2"
    location = "Central US"    
    route = {
      route_1 = {
        name           = "route1"
        address_prefix = "10.1.0.0/16"
        next_hop_type  = "vnetlocal"
      }     
    }
  }    
}

# -
# - Subnets
# - 
subnets = {
  subnet_1 = {
    name                   = "subnet1"
    vnet_key               = "vnet1"
    address_prefixes       = ["10.0.1.0/24"]
  }
  subnet_2 = {
    name                   = "subnet2"
    vnet_key               = "vnet1"
    address_prefixes       = ["10.0.2.0/24"]
  }
  subnet_3 = {
    name                   = "subnet3"
    vnet_key               = "vnet1"
    address_prefixes       = ["10.0.3.0/24"]
  }
  # Secondary
  subnet_4 = {
    name                   = "subnet1"
    vnet_key               = "vnet2"
    address_prefixes       = ["10.0.1.0/24"]
  }
  subnet_5 = {
    name                   = "subnet2"
    vnet_key               = "vnet2"
    address_prefixes       = ["10.0.2.0/24"]
  }
  subnet_6 = {
    name                   = "subnet3"
    vnet_key               = "vnet2"
    address_prefixes       = ["10.0.3.0/24"]
  }  
}

# -
# - Route Table Association
# - 
route_table_association = {
  rta1 = {
    subnet_key      = "subnet_1"
    route_table_key = "rt_1"
  }
  rta2 = {
    subnet_key      = "subnet_4"
    route_table_key = "rt_2"
  }  
}

# -
# - Network Security Group Association
# - 
network_security_group_association = {
  nsga1 = {
    subnet_key = "subnet_3"
    nsg_key    = "nsg_1"
  }
  nsga2 = {
    subnet_key = "subnet_6"
    nsg_key    = "nsg_2"
  }  
}
