variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "apim_publisher_name" {
  description = "Publisher name for API Management"
  type        = string
}

variable "apim_publisher_email" {
  description = "Publisher email for API Management"
  type        = string
}

variable "apim_sku" {
  description = "SKU for API Management - StandardV2_1 required for MCP support"
  type        = string
  default     = "StandardV2_1"
}

variable "function_app_sku" {
  description = "SKU for Function App Service Plan"
  type        = string
  default     = "Y1"
}