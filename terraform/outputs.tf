output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "The name of the resource group"
}

output "apim_gateway_url" {
  value       = module.apim.gateway_url
  description = "The gateway URL for API Management"
}

output "function_app_url" {
  value       = module.function_app.function_app_url
  description = "The URL of the Function App"
}

output "mcp_endpoint" {
  value       = module.function_app.mcp_endpoint
  description = "The MCP endpoint URL for SSE connection"
}

output "entra_app_client_id" {
  value       = module.app_registration.client_id
  description = "The client ID of the Entra ID application"
}

output "entra_app_tenant_id" {
  value       = module.app_registration.tenant_id
  description = "The tenant ID for authentication"
}