# OAuth API for MCP Authentication
resource "azurerm_api_management_api" "oauth" {
  name                  = "oauth-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.main.name
  revision              = "1"
  display_name          = "OAuth API"
  path                  = ""  # Root level, no path prefix for VSCode OAuth
  protocols             = ["https"]
  subscription_required = false

  import {
    content_format = "openapi+json"
    content_value = jsonencode({
      openapi = "3.0.1"
      info = {
        title   = "OAuth API"
        version = "1.0"
      }
      servers = [{
        url = "/"
      }]
      paths = {
        "/authorize" = {
          get = {
            summary     = "OAuth Authorization Endpoint"
            description = "OAuth Authorization Endpoint"
            operationId = "oauth-authorize"
            parameters = [
              {
                name        = "client_id"
                in          = "query"
                required    = true
                schema      = { type = "string" }
              },
              {
                name        = "redirect_uri"
                in          = "query"
                required    = true
                schema      = { type = "string" }
              },
              {
                name        = "response_type"
                in          = "query"
                required    = true
                schema      = { type = "string" }
              },
              {
                name        = "state"
                in          = "query"
                required    = false
                schema      = { type = "string" }
              },
              {
                name        = "code_challenge"
                in          = "query"
                required    = false
                schema      = { type = "string" }
              },
              {
                name        = "code_challenge_method"
                in          = "query"
                required    = false
                schema      = { type = "string" }
              }
            ]
            responses = {
              "302" = {
                description = "Redirect to authorization server"
              }
            }
          }
        }
        "/.well-known/oauth-authorization-server" = {
          get = {
            summary     = "OAuth Authorization Server Metadata"
            operationId = "oauth-metadata"
            responses = {
              "200" = {
                description = "OAuth metadata"
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
        "/.well-known/mcp/protected-resource-metadata.json" = {
          get = {
            summary     = "Protected Resource Metadata for MCP OAuth"
            operationId = "prm-metadata"
            responses = {
              "200" = {
                description = "PRM metadata"
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
        "/.well-known/oauth-protected-resource" = {
          get = {
            summary     = "RFC 9728 Protected Resource Metadata"
            operationId = "prm-rfc"
            responses = {
              "200" = {
                description = "PRM metadata RFC 9728"
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
        "/callback" = {
          get = {
            summary     = "OAuth Callback Endpoint"
            description = "OAuth Callback Endpoint"
            operationId = "oauth-callback"
            parameters = [
              {
                name        = "code"
                in          = "query"
                required    = true
                schema      = { type = "string" }
              },
              {
                name        = "state"
                in          = "query"
                required    = false
                schema      = { type = "string" }
              }
            ]
            responses = {
              "302" = {
                description = "Redirect back to client"
              }
            }
          }
        }
        "/token" = {
          post = {
            summary     = "OAuth Token Endpoint"
            description = "OAuth Token Endpoint"
            operationId = "oauth-token"
            requestBody = {
              required = true
              content = {
                "application/x-www-form-urlencoded" = {
                  schema = {
                    type = "object"
                    properties = {
                      grant_type = {
                        type = "string"
                      }
                      code = {
                        type = "string"
                      }
                      code_verifier = {
                        type = "string"
                      }
                      client_id = {
                        type = "string"
                      }
                      redirect_uri = {
                        type = "string"
                      }
                    }
                  }
                }
              }
            }
            responses = {
              "200" = {
                description = "Token response"
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

# OAuth API Operation Policies
resource "azurerm_api_management_api_operation_policy" "oauth_authorize" {
  api_name            = azurerm_api_management_api.oauth.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  operation_id        = "oauth-authorize"

  xml_content = file("${path.module}/policies/oauth-authorize.xml")
}

# OAuth metadata endpoint policy
resource "azurerm_api_management_api_operation_policy" "oauth_metadata" {
  api_name            = azurerm_api_management_api.oauth.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  operation_id        = "oauth-metadata"

  xml_content = <<XML
<policies>
    <inbound>
        <base />
        <return-response>
            <set-status code="200" reason="OK" />
            <set-header name="Content-Type" exists-action="override">
                <value>application/json</value>
            </set-header>
            <set-body>@{
                var host = context.Request.Headers.GetValueOrDefault("Host", "apim-mcp-dev-7204b7.azure-api.net");
                var baseUrl = "https://" + host;
                return "{" +
                    "\"issuer\": \"" + baseUrl + "\"," +
                    "\"authorization_endpoint\": \"" + baseUrl + "/authorize\"," +
                    "\"token_endpoint\": \"" + baseUrl + "/token\"," +
                    "\"token_endpoint_auth_methods_supported\": [\"client_secret_post\", \"client_secret_basic\"]," +
                    "\"grant_types_supported\": [\"authorization_code\", \"refresh_token\"]," +
                    "\"response_types_supported\": [\"code\"]," +
                    "\"scopes_supported\": [\"api.read\", \"api.write\", \"openid\", \"profile\"]," +
                    "\"code_challenge_methods_supported\": [\"S256\", \"plain\"]" +
                "}";
            }</set-body>
        </return-response>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
XML
}

# OAuth callback endpoint policy
resource "azurerm_api_management_api_operation_policy" "oauth_callback" {
  api_name            = azurerm_api_management_api.oauth.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  operation_id        = "oauth-callback"

  xml_content = file("${path.module}/policies/oauth-callback.xml")
}

# OAuth token endpoint policy
resource "azurerm_api_management_api_operation_policy" "oauth_token" {
  api_name            = azurerm_api_management_api.oauth.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  operation_id        = "oauth-token"

  xml_content = file("${path.module}/policies/oauth-token.xml")
}

# Protected Resource Metadata policy
resource "azurerm_api_management_api_operation_policy" "prm_metadata" {
  api_name            = azurerm_api_management_api.oauth.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  operation_id        = "prm-metadata"

  xml_content = file("${path.module}/policies/prm-policy.xml")
}

# RFC 9728 Protected Resource Metadata policy
resource "azurerm_api_management_api_operation_policy" "prm_rfc" {
  api_name            = azurerm_api_management_api.oauth.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  operation_id        = "prm-rfc"

  xml_content = file("${path.module}/policies/prm-policy.xml")
}