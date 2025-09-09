# Azure CLI Commands Reference - MCP OAuth Implementation

## Complete CLI Command History

### 1. App Registration Commands

```bash
# Show app registration details
az ad app show --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47 \
  --query "{appId:appId, displayName:displayName, identifierUris:identifierUris}" -o json

# Set Application ID URI (CRITICAL)
az ad app update --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47 \
  --identifier-uris "api://108d6e4f-35d4-4894-a0d9-6cb83b198a47"

# Check OAuth2 permission scopes
az ad app show --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47 \
  --query "api.oauth2PermissionScopes" -o json

# List app registrations
az ad app list --display-name "MCP Server" \
  --query "[].{appId:appId, displayName:displayName, identifierUris:identifierUris}" -o json

# Search for MCP-related apps
az ad app list --filter "startswith(displayName, 'MCP')" \
  --query "[].{appId:appId, displayName:displayName, identifierUris:identifierUris}" -o json
```

### 2. Service Principal Commands

```bash
# Check if service principal exists
az ad sp show --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47 \
  --query "{appId:appId, displayName:appDisplayName}" -o json

# Create service principal if missing
az ad sp create --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47

# Show service principal with all details
az ad sp show --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47
```

### 3. Permission and Consent Commands

```bash
# Grant admin consent for app permissions
az ad app permission admin-consent --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47

# Try to get access token (for testing)
az account get-access-token --resource "api://108d6e4f-35d4-4894-a0d9-6cb83b198a47" \
  --query accessToken -o tsv

# Login with specific scope if needed
az login --scope api://108d6e4f-35d4-4894-a0d9-6cb83b198a47/.default
```

### 4. API Management Commands

```bash
# List APIs in APIM
az apim api list --resource-group rg-mcp-dev \
  --service-name apim-mcp-dev-7204b7 \
  --query "[].{name:name, path:path}" -o json

# Show specific API details
az apim api show --resource-group rg-mcp-dev \
  --service-name apim-mcp-dev-7204b7 \
  --api-id mcp-api \
  --query "serviceUrl" -o tsv

# List API operations
az apim api operation list --resource-group rg-mcp-dev \
  --service-name apim-mcp-dev-7204b7 \
  --api-id mcp-api \
  --query "[].{name:name, method:method, urlTemplate:urlTemplate}" -o json

# Show specific operation
az apim api operation show --resource-group rg-mcp-dev \
  --service-name apim-mcp-dev-7204b7 \
  --api-id oauth-api \
  --operation-id oauth-authorize
```

### 5. Function App Commands

```bash
# Check function app status
az functionapp show --name func-mcp-dev-7204b7 \
  --resource-group rg-mcp-dev \
  --query "state" -o tsv

# List functions in app
az functionapp function list --name func-mcp-dev-7204b7 \
  --resource-group rg-mcp-dev \
  --query "[].{name:name, trigger:config.bindings[0].type}" -o json

# Deploy function app code
az functionapp deployment source config-zip \
  --resource-group rg-mcp-dev \
  --name func-mcp-dev-7204b7 \
  --src function-app-deploy.zip \
  --build-remote true

# Check deployment logs
az functionapp log deployment show --name func-mcp-dev-7204b7 \
  --resource-group rg-mcp-dev \
  --query "[-1].{message:message, time:log_time}" -o json

# Show function app configuration
az functionapp config show --name func-mcp-dev-7204b7 \
  --resource-group rg-mcp-dev \
  --query "linuxFxVersion" -o tsv

# Get function app URL
az functionapp show --name func-mcp-dev-7204b7 \
  --resource-group rg-mcp-dev \
  --query "defaultHostName" -o tsv
```

### 6. Testing Commands

```bash
# Test OAuth authorization endpoint
curl -I "https://apim-mcp-dev-7204b7.azure-api.net/authorize?\
client_id=108d6e4f-35d4-4894-a0d9-6cb83b198a47&\
response_type=code&\
redirect_uri=http://localhost:3000&\
scope=api://108d6e4f-35d4-4894-a0d9-6cb83b198a47/user_impersonation"

# Test PRM endpoint
curl -s https://apim-mcp-dev-7204b7.azure-api.net/.well-known/mcp/protected-resource-metadata.json \
  | python3 -m json.tool

# Test RFC 9728 PRM endpoint
curl -s https://apim-mcp-dev-7204b7.azure-api.net/.well-known/oauth-protected-resource \
  | python3 -m json.tool

# Test OAuth metadata endpoint
curl -s https://apim-mcp-dev-7204b7.azure-api.net/.well-known/oauth-authorization-server \
  | python3 -m json.tool

# Test MCP endpoint without auth (should return 401)
curl -s -X POST https://apim-mcp-dev-7204b7.azure-api.net/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{},"id":1}' \
  -w "\nHTTP_CODE:%{http_code}\n"

# Test function directly (bypasses APIM auth)
curl -X POST https://func-mcp-dev-7204b7.azurewebsites.net/api/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{},"id":1}'

# Test SSE endpoint
curl -s -X GET https://apim-mcp-dev-7204b7.azure-api.net/mcp \
  -H "Accept: text/event-stream" \
  -w "\nHTTP_CODE:%{http_code}\n"
```

### 7. Terraform Commands

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply all changes
terraform apply -auto-approve

# Apply specific target
terraform apply -auto-approve -target=module.apim.azurerm_api_management_subscription.mcp

# Refresh state
terraform refresh

# Show state
terraform state list

# Show specific resource
terraform state show module.app_registration.azuread_application.mcp_server

# Get outputs
terraform output -json

# Get specific output
terraform output -json | jq -r '.entra_app_client_id.value'
```

### 8. Package Creation Commands

```bash
# Create function app deployment package
cd function-app-src
zip -r ../function-app-deploy.zip . -x "*.zip"
cd ..

# List files in package
unzip -l function-app-deploy.zip

# Create backup of current state
tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz terraform/
```

### 9. Debugging Commands

```bash
# Check APIM traces (if enabled)
az apim api operation show --resource-group rg-mcp-dev \
  --service-name apim-mcp-dev-7204b7 \
  --api-id mcp-api \
  --operation-id mcp-jsonrpc

# Get function app logs
az functionapp log deployment list --name func-mcp-dev-7204b7 \
  --resource-group rg-mcp-dev

# Test with verbose curl
curl -v -X POST https://apim-mcp-dev-7204b7.azure-api.net/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{},"id":1}' 2>&1

# Get HTTP response code only
curl -s -o /dev/null -w "%{http_code}" \
  https://apim-mcp-dev-7204b7.azure-api.net/mcp
```

### 10. Resource Group Commands

```bash
# List all resources in resource group
az resource list --resource-group rg-mcp-dev \
  --query "[].{name:name, type:type}" -o table

# Show resource group
az group show --name rg-mcp-dev

# Get resource group location
az group show --name rg-mcp-dev --query location -o tsv
```

## Environment Variables Used

```bash
# These are typically set or retrieved
export TENANT_ID="90477fac-f56f-4b7b-8885-b6c2b2f78ff2"
export CLIENT_ID="108d6e4f-35d4-4894-a0d9-6cb83b198a47"
export RESOURCE_GROUP="rg-mcp-dev"
export APIM_NAME="apim-mcp-dev-7204b7"
export FUNCTION_APP="func-mcp-dev-7204b7"
```

## Quick Verification Script

```bash
#!/bin/bash
# Save as verify-oauth.sh

echo "Checking App Registration..."
az ad app show --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47 --query identifierUris -o json

echo "Checking Service Principal..."
az ad sp show --id 108d6e4f-35d4-4894-a0d9-6cb83b198a47 --query appId -o tsv

echo "Checking Function App..."
az functionapp show --name func-mcp-dev-7204b7 --resource-group rg-mcp-dev --query state -o tsv

echo "Testing PRM Endpoint..."
curl -s https://apim-mcp-dev-7204b7.azure-api.net/.well-known/mcp/protected-resource-metadata.json | python3 -m json.tool | head -5

echo "Testing MCP Endpoint (should return 401)..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" https://apim-mcp-dev-7204b7.azure-api.net/mcp
```

## Notes

- Always use `--build-remote true` when deploying Python function apps
- The Application ID URI must be set for OAuth to work
- Admin consent is required for the app permissions
- VSCode caches OAuth tokens, restart to clear
- APIM policies use `{{tenant-id}}` and `{{client-id}}` as named values
- Function apps need both `host.json` and `requirements.txt`