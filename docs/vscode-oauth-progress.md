# VS Code OAuth Implementation Progress

## Current Status
We discovered that Den's implementation uses a **completely different authentication approach** than standard OAuth Bearer tokens.

## What We Implemented (Standard OAuth Approach)

### 1. OAuth Endpoints Created
- **API**: `oauth` (at root level, no path prefix)
- **Operations**:
  - `/authorize` - Redirects to Microsoft Entra ID
  - `/token` - Forwards token requests to Entra ID  
  - `/callback` - Handles OAuth callback
  - `/register` - Dynamic client registration

### 2. Protected Resource Metadata (PRM) Endpoint
- **API**: `wellknown`
- **Path**: `/wellknown/mcp/protected-resource-metadata.json`
- **Current Policy**: Returns PRM document pointing to Entra ID
```json
{
  "resource": "https://apim-mcp-dev-7204b7.azure-api.net/mcp",
  "authorization_servers": [
    "https://login.microsoftonline.com/organizations/v2.0"
  ],
  "scopes_supported": ["User.Read"],
  "bearer_methods_supported": ["header"],
  "resource_name": "MCP API"
}
```

### 3. MCP API Policy
- **API**: `mcp-api`
- **Path**: `/mcp`
- **Current Policy Name**: Standard JWT validation
- Returns 401 with `WWW-Authenticate: Bearer resource_metadata="..."` header
- Validates JWT tokens from Microsoft

### 4. App Registration Configuration
- **App ID**: `108d6e4f-35d4-4894-a0d9-6cb83b198a47`
- **Tenant ID**: `90477fac-f56f-4b7b-8885-b6c2b2f78ff2`
- Configured to allow personal Microsoft accounts
- Pre-authorized VS Code's client ID: `aebc6443-996d-45c2-90f0-388ff96faa56`

### 5. VS Code MCP Configuration
Location: `/Users/connorokane/Documents/repos/personal/APIM-MCP/.vscode/mcp.json`
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

## What Den Actually Implemented (Custom Session Key Approach)

### Key Differences Discovered
1. **Does NOT use standard JWT Bearer tokens**
2. **Uses encrypted session keys** in Authorization header
3. **Stores actual Entra tokens in APIM cache**
4. **Decrypts session key to lookup cached tokens**
5. **Injects bearer token into request body (not header)**

### Den's Flow
1. Client gets 401 (mechanism unknown - no PRM found in repo)
2. Client goes through custom OAuth flow with:
   - `/authorize` endpoint with consent management
   - `/oauth-callback` that creates encrypted session
   - Stores token in cache with session key
3. Client uses encrypted session key as Authorization header
4. MCP API decrypts session key, retrieves cached token, injects into body

## Issues with Standard Approach
- VS Code successfully gets Microsoft Graph token
- But doesn't prompt for authentication when needed
- Sends cached invalid tokens without re-authenticating
- VS Code's built-in OAuth support seems incomplete for MCP
