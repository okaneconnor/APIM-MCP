locals {
  resource_names = {
    resource_group       = "rg-${var.resource_prefix}-${var.environment}"
    apim                = "apim-${var.resource_prefix}-${var.environment}-${substr(md5("${var.resource_prefix}-${var.environment}"), 0, 6)}"
    function_app        = "func-${var.resource_prefix}-${var.environment}-${substr(md5("${var.resource_prefix}-${var.environment}"), 0, 6)}"
    storage_account     = "st${var.resource_prefix}${var.environment}${substr(md5("${var.resource_prefix}-${var.environment}"), 0, 6)}"
    app_service_plan    = "asp-${var.resource_prefix}-${var.environment}"
    service_plan        = "asp-${var.resource_prefix}-${var.environment}"
    app_insights        = "ai-${var.resource_prefix}-${var.environment}"
    log_analytics       = "log-${var.resource_prefix}-${var.environment}"
  }

  common_tags = {
    environment = var.environment
    project     = "mcp-server"
    managed_by  = "terraform"
  }
}