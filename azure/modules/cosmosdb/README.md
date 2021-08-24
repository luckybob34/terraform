![Terraform](https://img.shields.io/badge/terraform-v1.0.0-%235835CC.svg) ![Cloud](https://img.shields.io/badge/cloud-Azure-blue) ![Module](https://img.shields.io/static/v1.svg?label=Module&message=v1.0&color=green)

## Example Arguments Definition File
`template.tfvars`

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_cosmosdb_account.cdba1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_account) | resource |
| [azurerm_cosmosdb_sql_container.sqlc1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_container) | resource |
| [azurerm_cosmosdb_sql_database.sql1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_database) | resource |
| [azurerm_monitor_diagnostic_setting.mds1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_private_endpoint.ape1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_log_analytics_workspace.law1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/log_analytics_workspace) | data source |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.sub1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cosmosdb_accounts"></a> [cosmosdb\_accounts](#input\_cosmosdb\_accounts) | The CosmosDB Accounts with their properties. | `any` | n/a | yes |
| <a name="input_cosmosdb_rg"></a> [cosmosdb\_rg](#input\_cosmosdb\_rg) | The CosmosDB resources group name. | `string` | n/a | yes |
| <a name="input_cosmosdb_sql_containers"></a> [cosmosdb\_sql\_containers](#input\_cosmosdb\_sql\_containers) | The CosmosDB SQL Containers with their properties. | `any` | n/a | yes |
| <a name="input_cosmosdb_sql_databases"></a> [cosmosdb\_sql\_databases](#input\_cosmosdb\_sql\_databases) | The CosmosDB SQL Databases with their properties. | `any` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Current environment | `string` | n/a | yes |
| <a name="input_log_analytics_workspace"></a> [log\_analytics\_workspace](#input\_log\_analytics\_workspace) | The Log Analytics Workspaces with their properties. | `any` | n/a | yes |
| <a name="input_monitor_diagnostic_settings"></a> [monitor\_diagnostic\_settings](#input\_monitor\_diagnostic\_settings) | The Monitor Diagnostic Settings with their properties. | `any` | n/a | yes |
| <a name="input_null_array"></a> [null\_array](#input\_null\_array) | - - Other - | `list` | `[]` | no |
| <a name="input_private_endpoints"></a> [private\_endpoints](#input\_private\_endpoints) | The Private Endpoints with their properties. | `any` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | The Subnets with their properties. | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cosmosdb_accounts"></a> [cosmosdb\_accounts](#output\_cosmosdb\_accounts) | Map output of the CosmosDB Account |
| <a name="output_cosmosdb_sql_databases"></a> [cosmosdb\_sql\_databases](#output\_cosmosdb\_sql\_databases) | Map output of the CosmosDB SQL Databases |