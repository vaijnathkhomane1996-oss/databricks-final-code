# Data source to retrieve workspace URL and PAT from AWS Secrets Manager
# This allows automatic retrieval without manual input
# Uses try() to gracefully handle cases where secret doesn't exist yet

data "aws_secretsmanager_secret" "databricks_workspace" {
  count = var.use_secrets_manager ? 1 : 0
  name   = "${var.product_name}-${var.environment}-${var.region}-databricks-workspace"
}

data "aws_secretsmanager_secret_version" "databricks_workspace" {
  count     = var.use_secrets_manager ? 1 : 0
  secret_id = var.use_secrets_manager ? data.aws_secretsmanager_secret.databricks_workspace[0].id : null
}

locals {
  # Parse the secret JSON if secret exists and was successfully retrieved
  # Use try() to handle cases where secret doesn't exist or data source fails
  workspace_secrets = var.use_secrets_manager && length(data.aws_secretsmanager_secret_version.databricks_workspace) > 0 ? try(jsondecode(data.aws_secretsmanager_secret_version.databricks_workspace[0].secret_string), {}) : {}
  
  # Use provided values if available, otherwise retrieve from Secrets Manager, fallback to module output
  # Priority: override > Secrets Manager > module output/variable
  workspace_url = coalesce(
    var.workspace_url_override,
    try(local.workspace_secrets.workspace_url, null),
    try(module.workspace.workspace_url, null)  # Fallback to module output if secret doesn't exist yet
  )
  
  workspace_pat = coalesce(
    var.workspace_pat_override,
    try(local.workspace_secrets.workspace_pat, null),
    var.workspace_pat  # Fallback to variable if secret doesn't exist yet
  )
}
