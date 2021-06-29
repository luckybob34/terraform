# -
# - Data gathering
# -
data "azurerm_resource_group" "rg" {
  name = var.traffic_manager_rg
}

# -
# - Traffic Manager Profile
# -
resource "azurerm_traffic_manager_profile" "tm1" {
  for_each                       = var.traffic_manager_profiles
  name                           = "${var.environment}-${each.value["team"]}-${each.value["name"]}-${each.value["instance"]}-atm"   #(Required) The name of the Traffic Manager profile. Changing this forces a new resource to be created.
  resource_group_name            = data.azurerm_resource_group.rg.name              #(Required) The name of the resource group in which to create the Traffic Manager profile.
  profile_status                 = lookup(each.value, "profile_status" , null)       #(Optional) The status of the profile, can be set to either Enabled or Disabled. Defaults to Enabled.
  traffic_routing_method         = each.value["traffic_routing_method"]             #(Required) Specifies the algorithm used to route traffic
  traffic_view_enabled           = lookup(each.value, "traffic_view_enabled", null) #(Optional) Indicates whether Traffic View is enabled for the Traffic Manager profile.

  dns_config {                                                                      #(Required) This block specifies the DNS configuration of the Profile
    relative_name                = each.value["relative_name"]                      #(Required) (Unique)
    ttl                          = each.value["ttl"]                                #(Required)
  }

  monitor_config {                                                                  #(Required) This block specifies the Endpoint monitoring configuration for the Profile
    protocol                     = lookup(each.value, "protocol", "http")           #(Required) The protocol used by the monitoring checks, supported values are HTTP, HTTPS and TCP.
    port                         = lookup(each.value, "port", 80)                   #(Required) The port number used by the monitoring checks.
    path                         = lookup(each.value, "path", null)                 #(Optional) The path used by the monitoring checks. Required when protocol is set to HTTP or HTTPS - cannot be set when protocol is set to TCP.
    expected_status_code_ranges  = lookup(each.value, "expected_status_code_ranges", null) #(Optional) A list of status code ranges in the format of 100-101.
    
    dynamic "custom_header" {                                                       #(Optional)
      for_each = lookup(each.value, "custom_header", var.null_array)
      content {    
        name                     = lookup(custome_header.value, "name", null)       #(Required) The name of the custom header.
        value                    = lookup(custome_header.value, "value", null)      #(Required) The value of custom header. Applicable for Http and Https protocol.
      }
    }
    
    interval_in_seconds          = lookup(each.value, "interval_in_seconds", null)          #(Optional) The interval used to check the endpoint health from a Traffic Manager probing agent. You can specify two values here: 30 (normal probing) and 10 (fast probing). The default value is 30.
    timeout_in_seconds           = lookup(each.value, "timeout_in_seconds", null)           #(Optional) The amount of time the Traffic Manager probing agent should wait before considering that check a failure when a health check probe is sent to the endpoint. If interval_in_seconds is set to 30, then timeout_in_seconds can be between 5 and 10. The default value is 10. If interval_in_seconds is set to 10, then valid values are between 5 and 9 and timeout_in_seconds is required.
    tolerated_number_of_failures = lookup(each.value, "tolerated_number_of_failures", null) # (Optional) The number of failures a Traffic Manager probing agent tolerates before marking that endpoint as unhealthy. Valid values are between 0 and 9. The default value is 3
  }

  max_return                     = lookup(each.value, "max_return", null)            #(Optional) The amount of endpoints to return for DNS queries to this Profile. Possible values range from 1 to 8. 
}

# -
# - Traffic Manager Endpoints
# -
resource "azurerm_traffic_manager_endpoint" "tmep1" {
  for_each                       = var.traffic_manager_endpoints                                               
  name                           = "${var.environment}-${each.value["team"]}-${each.value["name"]}-${each.value["instance"]}-tmep"  #(Required) The name of the Traffic Manager endpoint. Changing this forces a new resource to be created.
  resource_group_name            = data.azurerm_resource_group.rg.name                                        #(Required) The name of the resource group where the Traffic Manager Profile exists.
  profile_name                   = lookup(azurerm_traffic_manager_profile.tm1, each.value["traffic_manager_profile_key"])["name"] #(Required) The name of the Traffic Manager Profile to attach create the Traffic Manager endpoint.
  endpoint_status                = lookup(each.value, "endpoint_status", null)                                #(Optional) The status of the Endpoint, can be set to either Enabled or Disabled. Defaults to Enabled.
  type                           = each.value["type"]                                                         #(Required) The Endpoint type, must be one of: azureEndpoints, externalEndpoints, nestedEndpoints
  target                         = lookup(each.value, "target", null)                                         #(Optional) The FQDN DNS name of the target. This argument must be provided for an endpoint of type externalEndpoints, for other types it will be computed.
  weight                         = each.value["weight"]                                                       #(Optional) Specifies how much traffic should be distributed to this endpoint, this must be specified for Profiles using the Weighted traffic routing method. Supports values between 1 and 1000.
  target_resource_id             = lookup(var.existing_app_services, each.value["app_service_key"])["id"]     #(Optional) The resource id of an Azure resource to target. This argument must be provided for an endpoint of type azureEndpoints or nestedEndpoints.  
}
