resource "random_string" "unique" {
  length  = 6
  special = false
  upper   = false
}

locals {
  resource_suffix = "${var.environment}-${random_string.unique.result}"

  resource_names = {
    resource_group  = "rg-mcp-apim-${local.resource_suffix}"
    storage_account = "stmcp${replace(local.resource_suffix, "-", "")}"
    service_plan    = "asp-mcp-${local.resource_suffix}"
    function_app    = "func-mcp-${local.resource_suffix}"
    apim            = "apim-mcp-${local.resource_suffix}"
  }
}