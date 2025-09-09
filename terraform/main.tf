# Main Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_names.resource_group
  location = var.location
  tags     = local.common_tags
}

# App Registration Module
module "app_registration" {
  source = "./modules/app-registration"
  
  environment   = var.environment
  apim_hostname = "${local.resource_names.apim}.azure-api.net"
}

# Function App Module
module "function_app" {
  source = "./modules/function-app"
  
  resource_group_name  = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  function_app_name   = local.resource_names.function_app
  storage_account_name = local.resource_names.storage_account
  service_plan_name   = local.resource_names.service_plan
  function_app_sku    = var.function_app_sku
  tenant_id           = module.app_registration.tenant_id
  client_id           = module.app_registration.client_id
  tags                = local.common_tags
}

# API Management Module
module "apim" {
  source = "./modules/apim"
  
  resource_group_name   = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  apim_name            = local.resource_names.apim
  apim_sku             = var.apim_sku
  apim_publisher_name  = var.apim_publisher_name
  apim_publisher_email = var.apim_publisher_email
  function_app_hostname = "${local.resource_names.function_app}.azurewebsites.net"
  client_id            = module.app_registration.client_id
  client_secret        = module.app_registration.client_secret
  tenant_id            = module.app_registration.tenant_id
  identifier_uri       = module.app_registration.identifier_uri
  function_host_key    = ""  # Add actual key if available
  enable_mcp_auth      = true  # Set to true to enable authentication
  tags                 = local.common_tags
}