variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "apim_name" {
  type        = string
  description = "API Management instance name"
}

variable "apim_sku" {
  type        = string
  description = "API Management SKU"
}

variable "apim_publisher_name" {
  type        = string
  description = "API Management publisher name"
}

variable "apim_publisher_email" {
  type        = string
  description = "API Management publisher email"
}

variable "function_app_hostname" {
  type        = string
  description = "Function App hostname"
}

variable "client_id" {
  type        = string
  description = "Entra ID application client ID"
}

variable "client_secret" {
  type        = string
  sensitive   = true
  description = "Entra ID application client secret"
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
}

variable "identifier_uri" {
  type        = string
  description = "Entra ID application identifier URI"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}

variable "session_encryption_key" {
  type        = string
  sensitive   = true
  description = "Key for encrypting session data (auto-generated if not provided)"
  default     = ""
}

variable "function_host_key" {
  type        = string
  sensitive   = true
  description = "Function App host key for authentication"
  default     = ""
}

variable "enable_mcp_auth" {
  type        = bool
  description = "Enable authentication for MCP API (set to false for development)"
  default     = true
}