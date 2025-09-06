# Service Plan for Function App
resource "azurerm_service_plan" "functions" {
  name                = local.resource_names.service_plan
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = var.function_app_sku
}

# Function App for MCP Server
resource "azurerm_linux_function_app" "mcp_server" {
  name                       = local.resource_names.function_app
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  service_plan_id            = azurerm_service_plan.functions.id
  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "PYTHON_VERSION"                 = "3.11"
    "AzureWebJobsStorage"            = azurerm_storage_account.functions.primary_connection_string
    "APIM_GATEWAY_URL"               = azurerm_api_management.main.gateway_url
    "ENABLE_ORYX_BUILD"              = "true"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }

    cors {
      allowed_origins = ["https://${azurerm_api_management.main.gateway_url}", "*"]
    }
  }
}