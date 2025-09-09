output "function_app_hostname" {
  value       = azurerm_linux_function_app.main.default_hostname
  description = "The hostname of the Function App"
}

output "function_app_url" {
  value       = "https://${azurerm_linux_function_app.main.default_hostname}"
  description = "The URL of the Function App"
}

output "mcp_endpoint" {
  value       = "https://${azurerm_linux_function_app.main.default_hostname}/api/mcp"
  description = "The MCP endpoint URL"
}