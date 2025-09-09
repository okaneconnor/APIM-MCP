# API Management Instance
resource "azurerm_api_management" "main" {
  name                = var.apim_name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = var.apim_sku
  tags                = var.tags
}

# Removed - replaced by native MCP support in mcp-api.tf

# API Management Product
resource "azurerm_api_management_product" "mcp" {
  product_id            = "mcp-product"
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.main.name
  display_name          = "MCP Server Product"
  description           = "Product for MCP Server API access with CRUD operations"
  subscription_required = true
  approval_required     = false
  published             = true
}

# Link API to Product
resource "azurerm_api_management_product_api" "mcp" {
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main.name
  product_id          = azurerm_api_management_product.mcp.product_id
  api_name            = azurerm_api_management_api.mcp_api.name
}

# Subscription for the product
resource "azurerm_api_management_subscription" "mcp" {
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main.name
  product_id          = azurerm_api_management_product.mcp.id
  display_name        = "MCP Server Subscription"
  state               = "active"
  allow_tracing       = true
}