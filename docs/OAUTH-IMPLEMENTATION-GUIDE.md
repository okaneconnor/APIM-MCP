# Azure API Management MCP OAuth Implementation Guide

## Overview
This guide documents the complete implementation of OAuth authentication for Model Context Protocol (MCP) servers using Azure API Management (APIM) and Microsoft Entra ID (formerly Azure AD).

## Architecture Components
1. **Azure API Management** - API gateway handling OAuth flows and token validation
2. **Microsoft Entra ID** - Identity provider for OAuth authentication
3. **Azure Functions** - Backend MCP server implementation
4. **VSCode MCP Extension** - Client consuming the MCP API

## Prerequisites
- Azure subscription
- Azure CLI installed and authenticated
- Terraform installed
- VSCode with MCP extension

## Step-by-Step Implementation

### 1. App Registration Setup

#### Create App Registration
```bash
# The app registration with ID 108d6e4f-35d4-4894-a0d9-6cb83b198a47 was created
# Display name: mcp-apim-oauth-app-dev

# Set the Application ID URI (CRITICAL - without this, you get "resource principal not found" error)
az ad app update --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47 \
  --identifier-uris "api://108d6e4f-35d4-4894-a0d9-6cb83b198a47"

# Verify the app registration
az ad app show --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47 \
  --query "{appId:appId, identifierUris:identifierUris, oauth2PermissionScopes:api.oauth2PermissionScopes[].value}"
```

#### Configure OAuth2 Permission Scopes
The app needs these scopes configured:
- `MCP.Read` - Allow reading from MCP servers
- `user_impersonation` - Access MCP Server on behalf of user

#### Set Reply URLs
Configure these redirect URIs in the app registration:
```
- http://localhost:33418
- http://127.0.0.1:33418
- vscode://github.copilot/auth/callback
- https://login.microsoftonline.com/common/oauth2/nativeclient
```

#### Create Service Principal
```bash
# Ensure service principal exists
az ad sp show --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47 || \
az ad sp create --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47
```

#### Grant Admin Consent
```bash
# Grant admin consent for the app permissions
az ad app permission admin-consent --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47
```

### 2. Azure API Management Configuration

#### OAuth API Endpoints
Created OAuth API with these endpoints at root level (path: ""):
- `/authorize` - Redirects to Microsoft OAuth
- `/token` - Proxies to Microsoft token endpoint
- `/.well-known/oauth-authorization-server` - OAuth metadata
- `/.well-known/mcp/protected-resource-metadata.json` - PRM for MCP
- `/.well-known/oauth-protected-resource` - RFC 9728 PRM

#### MCP API Configuration
- Path: `/mcp`
- Operations: GET (SSE), POST (JSON-RPC)
- Backend: Azure Functions
- Authentication: JWT validation with Entra ID

### 3. APIM Policy Files

#### OAuth Authorization Policy (`oauth-authorize.xml`)
```xml
<!-- OAuth Authorization Endpoint - Redirect to Microsoft -->
<policies>
    <inbound>
        <base />
        
        <!-- Redirect to Microsoft OAuth2 authorization endpoint -->
        <return-response>
            <set-status code="302" reason="Found" />
            <set-header name="Location" exists-action="override">
                <value>@{
                    // Build the Microsoft OAuth authorization URL
                    var queryString = context.Request.Url.QueryString;
                    
                    // Replace the scope if it's requesting access_as_user (old scope)
                    if (queryString.Contains("access_as_user")) {
                        queryString = queryString.Replace("access_as_user", "user_impersonation");
                    }
                    
                    // Redirect to Microsoft's authorization endpoint with all original parameters
                    return "https://login.microsoftonline.com/{{tenant-id}}/oauth2/v2.0/authorize" + queryString;
                }</value>
            </set-header>
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
```

#### OAuth Token Policy (`oauth-token.xml`)
```xml
<!-- OAuth Token Endpoint - Proxy to Microsoft -->
<policies>
    <inbound>
        <base />
        
        <!-- Forward token request to Microsoft's token endpoint -->
        <send-request mode="new" response-variable-name="tokenResponse" timeout="30" ignore-error="false">
            <set-url>https://login.microsoftonline.com/{{tenant-id}}/oauth2/v2.0/token</set-url>
            <set-method>POST</set-method>
            <set-header name="Content-Type" exists-action="override">
                <value>application/x-www-form-urlencoded</value>
            </set-header>
            <set-body>@(context.Request.Body.As<string>(preserveContent: true))</set-body>
        </send-request>
        
        <!-- Return Microsoft's response -->
        <return-response response-variable-name="tokenResponse">
            <set-status code="@(((IResponse)context.Variables["tokenResponse"]).StatusCode)" 
                       reason="@(((IResponse)context.Variables["tokenResponse"]).StatusReason)" />
            <set-header name="Content-Type" exists-action="override">
                <value>application/json</value>
            </set-header>
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
```

#### Protected Resource Metadata Policy (`prm-policy.xml`)
```xml
<!-- Protected Resource Metadata (PRM) Policy for MCP OAuth -->
<policies>
    <inbound>
        <base />
        
        <!-- Return PRM document for OAuth discovery -->
        <return-response>
            <set-status code="200" reason="OK" />
            <set-header name="Content-Type" exists-action="override">
                <value>application/json</value>
            </set-header>
            <set-body>@{
                // Protected Resource Metadata for OAuth discovery
                var host = context.Request.Headers.GetValueOrDefault("Host", "apim-mcp-dev-7204b7.azure-api.net");
                var baseUrl = "https://" + host;
                
                return "{" +
                    "\"resource\": \"" + baseUrl + "/mcp\"," +
                    "\"authorization_servers\": [" +
                        "\"https://login.microsoftonline.com/{{tenant-id}}/v2.0\"" +
                    "]," +
                    "\"scopes_supported\": [\"api://108d6e4f-35d4-4894-a0d9-6cb83b198a47/user_impersonation\", \"api://108d6e4f-35d4-4894-a0d9-6cb83b198a47/MCP.Read\"]," +
                    "\"bearer_methods_supported\": [\"header\"]," +
                    "\"resource_name\": \"APIM MCP Server\"," +
                    "\"resource_documentation\": \"https://github.com/Azure/api-management-policy-snippets\"" +
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
```

#### MCP API Authentication Policy (`mcp-auth-prm-policy.xml`)
```xml
<!-- MCP API Authentication Policy with PRM Support -->
<policies>
    <inbound>
        <base />
        
        <!-- Handle OPTIONS preflight requests (no auth required) -->
        <choose>
            <when condition="@(context.Request.Method == "OPTIONS")">
                <return-response>
                    <set-status code="200" />
                    <set-header name="Access-Control-Allow-Origin" exists-action="override">
                        <value>*</value>
                    </set-header>
                    <set-header name="Access-Control-Allow-Methods" exists-action="override">
                        <value>GET, POST, OPTIONS</value>
                    </set-header>
                    <set-header name="Access-Control-Allow-Headers" exists-action="override">
                        <value>Authorization, Content-Type</value>
                    </set-header>
                </return-response>
            </when>
        </choose>
        
        <!-- JWT Token Validation with PRM support -->
        <validate-jwt header-name="Authorization" 
                      failed-validation-httpcode="401" 
                      failed-validation-error-message="Unauthorized">
            
            <!-- OpenID configuration endpoint for your tenant -->
            <openid-config url="https://login.microsoftonline.com/{{tenant-id}}/v2.0/.well-known/openid-configuration" />
            
            <!-- Audiences that are allowed -->
            <audiences>
                <audience>api://{{client-id}}</audience>
                <audience>{{client-id}}</audience>
            </audiences>
            
            <!-- Token issuers -->
            <issuers>
                <issuer>https://sts.windows.net/{{tenant-id}}/</issuer>
                <issuer>https://login.microsoftonline.com/{{tenant-id}}/v2.0</issuer>
            </issuers>
        </validate-jwt>
        
        <!-- Set backend service to forward to function app MCP endpoint -->
        <set-backend-service base-url="https://{{function-app-hostname}}/api/mcp" />
        
    </inbound>
    
    <backend>
        <base />
    </backend>
    
    <outbound>
        <base />
        <!-- Add CORS headers -->
        <set-header name="Access-Control-Allow-Origin" exists-action="override">
            <value>*</value>
        </set-header>
    </outbound>
    
    <on-error>
        <base />
        <!-- Return 401 with WWW-Authenticate header pointing to PRM -->
        <choose>
            <when condition="@(context.Response.StatusCode == 401)">
                <set-header name="WWW-Authenticate" exists-action="override">
                    <value>@{
                        var host = context.Request.Headers.GetValueOrDefault("Host", "apim-mcp-dev-7204b7.azure-api.net");
                        return "Bearer resource_metadata=\"https://" + host + "/.well-known/mcp/protected-resource-metadata.json\"";
                    }</value>
                </set-header>
                <set-body>{"statusCode": 401, "message": "Unauthorized. Access token is missing or invalid."}</set-body>
            </when>
        </choose>
    </on-error>
</policies>
```

### 4. Function App Configuration

#### Function App Deployment
```bash
# Create deployment package
cd function-app-src
zip -r ../function-app-deploy.zip . -x "*.zip"
cd ..

# Deploy to Azure Functions
az functionapp deployment source config-zip \
  --resource-group rg-mcp-dev \
  --name func-mcp-dev-7204b7 \
  --src function-app-deploy.zip \
  --build-remote true
```

#### Required Files

**host.json**
```json
{
  "version": "2.0",
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true,
        "excludedTypes": "Request"
      }
    }
  },
  "extensionBundle": {
    "id": "Microsoft.Azure.Functions.ExtensionBundle",
    "version": "[4.*, 5.0.0)"
  }
}
```

**requirements.txt**
```
azure-functions
PyJWT
cryptography
requests
```

**function_app.py**
```python
import azure.functions as func
import json
import logging

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="mcp", methods=["GET", "POST", "OPTIONS"])
def mcp_handler(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('MCP handler received request')
    
    # Handle CORS preflight
    if req.method == "OPTIONS":
        return func.HttpResponse(
            "",
            status_code=200,
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                "Access-Control-Allow-Headers": "Authorization, Content-Type",
            }
        )
    
    # Handle SSE request (GET)
    if req.method == "GET":
        # Return SSE headers for MCP initialization
        return func.HttpResponse(
            "data: {\"jsonrpc\":\"2.0\",\"id\":1,\"result\":{}}\n\n",
            status_code=200,
            headers={
                "Content-Type": "text/event-stream",
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "Access-Control-Allow-Origin": "*",
            }
        )
    
    # Handle JSON-RPC request (POST)
    try:
        req_body = req.get_json()
    except ValueError:
        return func.HttpResponse(
            json.dumps({"error": "Invalid JSON"}),
            status_code=400,
            headers={"Content-Type": "application/json"}
        )
    
    method = req_body.get("method", "")
    request_id = req_body.get("id", 1)
    
    # MCP Protocol Handlers
    if method == "initialize":
        response = {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {},
                    "prompts": {},
                    "resources": {}
                },
                "serverInfo": {
                    "name": "apim-mcp-server",
                    "version": "1.0.0"
                }
            }
        }
    elif method == "tools/list":
        response = {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {
                "tools": [
                    {
                        "name": "hello",
                        "description": "A simple hello world tool",
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "name": {
                                    "type": "string",
                                    "description": "Name to greet"
                                }
                            },
                            "required": ["name"]
                        }
                    }
                ]
            }
        }
    elif method == "tools/call":
        tool_name = req_body.get("params", {}).get("name", "")
        if tool_name == "hello":
            name = req_body.get("params", {}).get("arguments", {}).get("name", "World")
            response = {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {
                    "content": [
                        {
                            "type": "text",
                            "text": f"Hello, {name}!"
                        }
                    ]
                }
            }
        else:
            response = {
                "jsonrpc": "2.0",
                "id": request_id,
                "error": {
                    "code": -32601,
                    "message": f"Unknown tool: {tool_name}"
                }
            }
    else:
        response = {
            "jsonrpc": "2.0",
            "id": request_id,
            "error": {
                "code": -32601,
                "message": f"Method not found: {method}"
            }
        }
    
    return func.HttpResponse(
        json.dumps(response),
        status_code=200,
        headers={
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        }
    )
```

### 5. VSCode Configuration

**.vscode/mcp.json**
```json
{
  "servers": {
    "apim-mcp-oauth": {
      "type": "http",
      "url": "https://apim-mcp-dev-7204b7.azure-api.net/mcp",
      "transport": "streamable-http"
    }
  }
}
```

### 6. Terraform Configuration

#### Main Configuration
```terraform
# main.tf
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
  function_host_key    = ""
  enable_mcp_auth      = true  # CRITICAL: Keep this true for authentication
  tags                 = local.common_tags
}
```

### 7. Testing Commands

#### Test OAuth Authorization
```bash
# Test authorization endpoint redirects to Microsoft
curl -I "https://apim-mcp-dev-7204b7.azure-api.net/authorize?client_id=108d6e4f-35d4-4894-a0d9-6cb83b198a47&response_type=code&redirect_uri=http://localhost:3000&scope=api://108d6e4f-35d4-4894-a0d9-6cb83b198a47/user_impersonation"
```

#### Test PRM Endpoints
```bash
# Test MCP PRM endpoint
curl -s https://apim-mcp-dev-7204b7.azure-api.net/.well-known/mcp/protected-resource-metadata.json | python3 -m json.tool

# Test RFC 9728 PRM endpoint
curl -s https://apim-mcp-dev-7204b7.azure-api.net/.well-known/oauth-protected-resource | python3 -m json.tool
```

#### Test MCP Endpoint
```bash
# Test without auth (should return 401)
curl -X POST https://apim-mcp-dev-7204b7.azure-api.net/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{},"id":1}'

# Test function directly (bypasses APIM auth)
curl -X POST https://func-mcp-dev-7204b7.azurewebsites.net/api/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{},"id":1}'
```

### 8. Common Issues and Solutions

#### Issue: "Resource principal not found"
**Solution**: Set the Application ID URI
```bash
az ad app update --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47 \
  --identifier-uris "api://108d6e4f-35d4-4894-a0d9-6cb83b198a47"
```

#### Issue: 404 on MCP endpoint
**Solution**: Deploy function app with host.json
```bash
# Ensure host.json exists
# Create deployment package with all files
# Deploy with build-remote flag
```

#### Issue: No auth prompt in VSCode
**Solution**: VSCode caches tokens. Either:
- Restart VSCode completely
- Remove and re-add the MCP server
- Clear VSCode's credential cache

#### Issue: OAuth redirect fails
**Solution**: Ensure OAuth API path is empty string ("") not "oauth"

### 9. Key Success Factors

1. **App Registration Must Have Identifier URI**: Without `api://` URI, authentication fails
2. **OAuth Endpoints at Root Level**: VSCode expects OAuth at root, not under a path
3. **Function App Needs host.json**: Without it, functions don't register
4. **PRM Must Return Correct Scopes**: Use actual app ID, not placeholders
5. **Service Principal Must Exist**: Create it if missing
6. **Admin Consent Required**: Grant consent for permissions
7. **CORS Headers Required**: For browser-based OAuth flow
8. **Token Validation Policy**: Must accept both issuer formats

### 10. OAuth Flow Sequence

1. VSCode requests `/mcp` endpoint
2. APIM returns 401 with WWW-Authenticate header pointing to PRM
3. VSCode fetches PRM from `/.well-known/mcp/protected-resource-metadata.json`
4. PRM tells VSCode to use Microsoft OAuth at `login.microsoftonline.com`
5. VSCode redirects user to `/authorize` on APIM
6. APIM redirects to Microsoft's OAuth authorize endpoint
7. User logs in with Microsoft account
8. Microsoft redirects back to VSCode with authorization code
9. VSCode calls `/token` endpoint with code
10. APIM proxies to Microsoft's token endpoint
11. Microsoft returns access token
12. VSCode uses token to call `/mcp` endpoint
13. APIM validates JWT token
14. APIM forwards request to Function App
15. Function App returns MCP response

## Conclusion

This implementation provides a secure, OAuth-protected MCP server using Azure services. The key was properly configuring the app registration with an identifier URI, implementing the OAuth proxy endpoints, and ensuring all the pieces work together with proper CORS and authentication policies.

The solution now allows VSCode to authenticate users via Microsoft Entra ID and securely access the MCP server through Azure API Management.