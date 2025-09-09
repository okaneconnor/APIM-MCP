# MCP API Configuration
resource "azurerm_api_management_api" "mcp_api" {
  name                  = "mcp-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.main.name
  revision              = "1"
  display_name          = "MCP API"
  path                  = "mcp"
  protocols             = ["https"]
  service_url           = "https://${var.function_app_hostname}/api"
  subscription_required = false

  import {
    content_format = "openapi+json"
    content_value  = jsonencode({
      openapi = "3.0.1"
      info = {
        title   = "MCP API"
        version = "1.0"
      }
      servers = [{
        url = "/mcp"
      }]
      paths = {
        "/" = {
          get = {
            summary     = "MCP SSE Endpoint"
            description = "Server-Sent Events endpoint for MCP initialization"
            operationId = "mcp-sse"
            responses = {
              "200" = {
                description = "SSE stream"
                content = {
                  "text/event-stream" = {
                    schema = {
                      type = "string"
                    }
                  }
                }
              }
            }
          }
          post = {
            summary     = "MCP JSON-RPC Endpoint"
            description = "JSON-RPC endpoint for MCP operations"
            operationId = "mcp-jsonrpc"
            requestBody = {
              required = true
              content = {
                "application/json" = {
                  schema = {
                    type = "object"
                  }
                }
              }
            }
            responses = {
              "200" = {
                description = "JSON-RPC response"
                content = {
                  "application/json" = {
                    schema = {
                      type = "object"
                    }
                  }
                }
              }
            }
          }
        }
      }
    })
  }
}

# MCP API Policy - Conditionally applies authentication
resource "azurerm_api_management_api_policy" "mcp_api_policy" {
  api_name            = azurerm_api_management_api.mcp_api.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name

  # Use authenticated policy with PRM in production, non-authenticated for development
  xml_content = var.enable_mcp_auth ? file("${path.module}/policies/mcp-auth-prm-policy.xml") : file("${path.module}/policies/mcp-noauth-policy.xml")
}

