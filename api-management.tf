# API Management Instance
resource "azurerm_api_management" "main" {
  name                = local.resource_names.apim
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = "StandardV2_1"
}

# API Management API for MCP Server
resource "azurerm_api_management_api" "mcp" {
  name                  = "mcp-server-api"
  resource_group_name   = azurerm_resource_group.main.name
  api_management_name   = azurerm_api_management.main.name
  revision              = "1"
  display_name          = "MCP Server API"
  path                  = "mcp"
  protocols             = ["https"]
  service_url           = "https://${azurerm_linux_function_app.mcp_server.default_hostname}/api"
  subscription_required = true

  subscription_key_parameter_names {
    header = "Ocp-Apim-Subscription-Key"
    query  = "subscription-key"
  }
}

# API Management Product
resource "azurerm_api_management_product" "mcp" {
  product_id            = "mcp-product"
  api_management_name   = azurerm_api_management.main.name
  resource_group_name   = azurerm_resource_group.main.name
  display_name          = "MCP Server Product"
  description           = "Product for MCP Server API access with CRUD operations"
  subscription_required = true
  approval_required     = false
  published             = true
}

# Link API to Product
resource "azurerm_api_management_product_api" "mcp" {
  api_name            = azurerm_api_management_api.mcp.name
  product_id          = azurerm_api_management_product.mcp.product_id
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
}

# API Management Subscription
resource "azurerm_api_management_subscription" "mcp" {
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "MCP Server Subscription"
  product_id          = azurerm_api_management_product.mcp.id
  state               = "active"
}

# Basic API Operation for health check
resource "azurerm_api_management_api_operation" "health" {
  operation_id        = "health-check"
  api_name            = azurerm_api_management_api.mcp.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Health Check"
  method              = "GET"
  url_template        = "/health"
  description         = "Health check endpoint"
}