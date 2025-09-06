output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_linux_function_app.mcp_server.name
}

output "function_app_url" {
  description = "URL of the Function App"
  value       = "https://${azurerm_linux_function_app.mcp_server.default_hostname}"
}

output "apim_gateway_url" {
  description = "API Management Gateway URL"
  value       = azurerm_api_management.main.gateway_url
}

output "apim_developer_portal_url" {
  description = "API Management Developer Portal URL"
  value       = azurerm_api_management.main.developer_portal_url
}

output "apim_subscription_key" {
  description = "API Management Subscription Key for MCP API"
  value       = azurerm_api_management_subscription.mcp.primary_key
  sensitive   = true
}

output "mcp_api_base_url" {
  description = "Base URL for MCP API through APIM"
  value       = "${azurerm_api_management.main.gateway_url}/mcp"
}