# - 
# - General
# -
location            = "East US 2"
resource_group_name = "test-law-rg"
resource_group_lock = "rg-lock"
environment         = "test"

# - 
# - Resource Tags
# -
resource_tags = {
  "environement" = "test"
}

# -
# - Log Analytics Workspace
# -
log_analytics_workspaces = {
    law_1 = {
        name              = "test01"
        location          = "East Us 2"
        sku               = "Free"
        retention_in_days = "7"
    }
    law_2 = {
        name              = "test02"
        location          = "Central US"
        sku               = "Free"
        retention_in_days = "7"
    }    
}