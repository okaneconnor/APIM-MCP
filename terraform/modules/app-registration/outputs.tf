output "client_id" {
  value       = azuread_application.mcp_server.client_id
  description = "The client ID of the Entra ID application"
}

output "tenant_id" {
  value       = data.azuread_client_config.current.tenant_id
  description = "The tenant ID for authentication"
}

output "client_secret" {
  value       = azuread_application_password.mcp_server.value
  sensitive   = true
  description = "The client secret for the application"
}

output "identifier_uri" {
  value       = azuread_application_identifier_uri.mcp_server.identifier_uri
  description = "The identifier URI for the application"
}