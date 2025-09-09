# Get current Azure AD configuration
data "azuread_client_config" "current" {}

# Create Application Registration for MCP Server
resource "azuread_application" "mcp_server" {
  display_name     = "mcp-apim-oauth-app-${var.environment}"
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"
  
  api {
    mapped_claims_enabled          = true
    requested_access_token_version = 2
    
    oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access MCP Server on behalf of the signed-in user"
      admin_consent_display_name = "Access MCP Server"
      enabled                     = true
      id                          = random_uuid.mcp_scope.result
      type                        = "User"
      user_consent_description   = "Allow the application to access MCP Server on your behalf"
      user_consent_display_name  = "Access MCP Server"
      value                       = "user_impersonation"
    }

    oauth2_permission_scope {
      admin_consent_description  = "Allow reading from MCP servers"
      admin_consent_display_name = "Read MCP Data"
      enabled                     = true
      id                          = random_uuid.mcp_read_scope.result
      type                        = "User"
      user_consent_description   = "Allow reading data from MCP servers"
      user_consent_display_name  = "Read MCP Data"
      value                       = "MCP.Read"
    }
  }

  app_role {
    allowed_member_types = ["User", "Application"]
    description          = "MCP Server User"
    display_name         = "MCP Server User"
    enabled              = true
    id                   = random_uuid.mcp_user_role.result
    value                = "MCP.User"
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }

    resource_access {
      id   = "37f7f235-527c-4136-accd-4a02d197296e" # openid
      type = "Scope"
    }

    resource_access {
      id   = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0" # email
      type = "Scope"
    }

    resource_access {
      id   = "14dad69e-099b-42c9-810b-d002981feec1" # profile
      type = "Scope"
    }
  }

  web {
    redirect_uris = [
      "https://${var.apim_hostname}/oauth2/callback",
      "https://oauth.pstmn.io/v1/callback",
      "http://localhost:8080/callback"
    ]

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }

  public_client {
    redirect_uris = [
      "https://login.microsoftonline.com/common/oauth2/nativeclient",
      "mcp://auth",
      "vscode://github.copilot/auth/callback",
      "http://127.0.0.1:33418",
      "http://localhost:33418"
    ]
  }

  single_page_application {
    redirect_uris = [
      "https://localhost:3000/callback",
      "https://github.dev/auth/callback"
    ]
  }
}

# Create Service Principal
resource "azuread_service_principal" "mcp_server" {
  client_id                    = azuread_application.mcp_server.client_id
  app_role_assignment_required = false
  owners                        = [data.azuread_client_config.current.object_id]
}

# Enable public client flows for the application
resource "azuread_application_fallback_public_client" "mcp_server" {
  application_id = azuread_application.mcp_server.id
  enabled        = true
}

# Create Client Secret
resource "azuread_application_password" "mcp_server" {
  application_id = azuread_application.mcp_server.id
  display_name   = "MCP Server Client Secret"
  end_date       = timeadd(timestamp(), "8760h") # 1 year

  lifecycle {
    ignore_changes = [end_date]
  }
}

# Random UUIDs for scopes and roles
resource "random_uuid" "mcp_scope" {}
resource "random_uuid" "mcp_read_scope" {}
resource "random_uuid" "mcp_user_role" {}

# Grant admin consent for the application
resource "azuread_service_principal_delegated_permission_grant" "mcp_graph_consent" {
  service_principal_object_id          = azuread_service_principal.mcp_server.object_id
  resource_service_principal_object_id = data.azuread_service_principal.graph.object_id
  claim_values                          = ["User.Read", "openid", "email", "profile"]
}

# Get Microsoft Graph Service Principal
data "azuread_service_principal" "graph" {
  client_id = "00000003-0000-0000-c000-000000000000"
}

# Set the identifier URI after application creation to avoid circular dependency
resource "azuread_application_identifier_uri" "mcp_server" {
  application_id = azuread_application.mcp_server.id
  identifier_uri = "api://${azuread_application.mcp_server.client_id}"
}