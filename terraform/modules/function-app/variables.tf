variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "function_app_name" {
  type        = string
  description = "Function App name"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name"
}

variable "service_plan_name" {
  type        = string
  description = "Service plan name"
}

variable "function_app_sku" {
  type        = string
  description = "Function App SKU"
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
}

variable "client_id" {
  type        = string
  description = "Entra ID application client ID"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}