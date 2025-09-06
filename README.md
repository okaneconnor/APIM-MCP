# Azure API Management with MCP (Model Context Protocol) Support

This repository contains Terraform infrastructure for deploying Azure API Management with MCP server support, enabling integration with AI tools like GitHub Copilot.

## 📋 Prerequisites

- Azure subscription
- Azure CLI installed and authenticated  
- Terraform >= 1.5.0
- Azure Provider >= 4.37.0 (for v2 SKU support)

## 🏗️ Infrastructure Components

### Deployed Resources
- **Resource Group**: Container for all resources
- **API Management (APIM)**: StandardV2_1 tier with native MCP support
- **Function App**: Python 3.11 runtime for hosting custom MCP servers
- **Storage Account**: Required for Function App operation
- **Service Plan**: Consumption plan (Y1) for cost optimization

### Resource Naming
Resources use a unique suffix generated during deployment to ensure global uniqueness

## 🚀 Deployment Steps

### 1. Clone and Configure
```bash
# Clone the repository
git clone <your-repo-url>
cd APIM-MCP

# Copy and update the terraform variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init -upgrade

# Review the deployment plan  
terraform plan

# Deploy the infrastructure (takes ~45-60 minutes for APIM)
terraform apply
```

### 3. Access MCP Features

With StandardV2 tier, MCP features are natively available without enrollment:

Access your APIM instance in the Azure Portal:
```
https://portal.azure.com/?Microsoft_Azure_ApiManagement=mcp
```

Navigate to: **APIs** → **MCP Servers (preview)**

⚠️ **Important**: Include the `?Microsoft_Azure_ApiManagement=mcp` parameter in the URL to access MCP preview features.

## 🔧 Using MCP Servers

### Adding MCP Servers

1. Navigate to your APIM instance → **APIs** → **MCP Servers (preview)**
2. Click **"+ Create MCP server"**
3. Select **"Connect to existing MCP server"**
4. Enter the MCP server details:
   - **Backend URL**: The MCP server endpoint
   - **Display Name**: Friendly name for the server
   - **Base Path**: API path (e.g., `/microsoft-learn`)
   - **Description**: Server description

### Example MCP Servers

**Microsoft Learn MCP**:
- **URL**: `https://mcp-servers-zqsz.onrender.com`
- **Base Path**: `/microsoft-learn`
- **Description**: Access Microsoft documentation and Azure resources

**Other Available Servers**:
- **Filesystem MCP** - File operations
- **GitHub MCP** - GitHub API access  
- **Postgres MCP** - Database operations
- **Slack MCP** - Slack integration

### Custom MCP Server Deployment

Deploy custom MCP servers to the Function App:
```bash
# Package and deploy your MCP server
cd your-mcp-server
zip -r ../mcp-server.zip .
az functionapp deployment source config-zip \
  --resource-group <your-rg> \
  --name <your-function-app> \
  --src ../mcp-server.zip
```

## 🔐 Authentication

### API Subscription Key
Get your subscription key:
```bash
terraform output -raw apim_subscription_key
```

### For GitHub Copilot Integration
1. Get the MCP server endpoint from your APIM
2. Configure it in GitHub Copilot settings
3. Use the subscription key for authentication

## 📊 Outputs

After deployment, you'll have access to:
```bash
# View all outputs
terraform output

# Specific outputs
terraform output apim_gateway_url
terraform output function_app_url
terraform output apim_subscription_key
```

## 💰 Cost Considerations

- **APIM StandardV2**: ~$140/month (production-ready with MCP support)
- **Function App**: Consumption plan (pay per execution)
- **Storage**: Standard LRS (locally redundant storage)

Estimated monthly cost: ~$140-160 for StandardV2 APIM + minimal Function App usage

## 🛠️ Troubleshooting

### MCP Options Not Visible
1. Ensure you're using the feature flag URL: `?Microsoft_Azure_ApiManagement=mcp`
2. Verify you're using StandardV2, BasicV2, or Premium tier
3. Check that deployment completed successfully

### Verify APIM Status
```bash
az apim show --name <your-apim> --resource-group <your-rg> --query "sku"
```

## 📚 References

- [Microsoft Blog: Expose REST APIs as MCP Servers](https://techcommunity.microsoft.com/blog/integrationsonazureblog/expose-rest-apis-as-mcp-servers-with-azure-api-management-and-api-center-now-in-/4415013)
- [Microsoft Docs: Export REST API to MCP Server](https://learn.microsoft.com/en-us/azure/api-management/export-rest-mcp-server)
- [Model Context Protocol](https://modelcontextprotocol.org)
- [MCP Registry](https://github.com/modelcontextprotocol/servers)

## 🏛️ Architecture

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────┐
│  GitHub Copilot │────▶│     APIM     │────▶│  Function   │
│   or AI Tools   │     │  (Gateway)   │     │     App     │
└─────────────────┘     └──────────────┘     └─────────────┘
                              │                      │
                              ▼                      ▼
                        ┌──────────┐          ┌──────────┐
                        │   MCP    │          │   MCP    │
                        │  Export  │          │  Servers │
                        └──────────┘          └──────────┘
```

## 🚦 Current Status

- ✅ Infrastructure deployed
- ✅ APIM enrolled in AI Gateway preview
- ⏳ Waiting for MCP feature activation (up to 2 hours)
- 🔜 Ready to import/export MCP servers

## 📝 Notes

- This is a **preview feature** and not generally available
- The enrollment persists with the APIM instance
- Don't delete and redeploy APIM to avoid re-enrollment delays
- MCP support requires the special portal URL with feature flag

## 🤝 Contributing

Feel free to submit issues or pull requests to improve this setup.

## 📄 License

MIT