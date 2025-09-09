# Named values for token validation

resource "azurerm_api_management_named_value" "tenant_id" {
  name                = "tenant-id"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main.name
  display_name        = "tenant-id"
  value               = var.tenant_id
}

resource "azurerm_api_management_named_value" "client_id" {
  name                = "client-id"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main.name
  display_name        = "client-id"
  value               = var.client_id
}

resource "azurerm_api_management_named_value" "function_app_hostname" {
  name                = "function-app-hostname"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main.name
  display_name        = "function-app-hostname"
  value               = var.function_app_hostname
}