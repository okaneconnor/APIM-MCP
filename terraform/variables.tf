variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, staging, production)"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Azure region for resources"
  default     = "eastus"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for resource names"
  default     = "mcp"
}

variable "apim_sku" {
  type        = string
  description = "API Management SKU"
  default     = "StandardV2_1"
}

variable "apim_publisher_name" {
  type        = string
  description = "API Management publisher name"
  default     = "MCP Organization"
}

variable "apim_publisher_email" {
  type        = string
  description = "API Management publisher email"
  default     = "admin@mcporg.com"
}

variable "function_app_sku" {
  type        = string
  description = "Function App SKU"
  default     = "Y1"
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
  default     = "c2334a32-a95a-4fa6-8492-aa68544efd8f"
}