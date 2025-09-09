output "gateway_url" {
  value       = azurerm_api_management.main.gateway_url
  description = "The gateway URL for API Management"
}

output "apim_hostname" {
  value       = replace(azurerm_api_management.main.gateway_url, "https://", "")
  description = "The APIM hostname without protocol"
}