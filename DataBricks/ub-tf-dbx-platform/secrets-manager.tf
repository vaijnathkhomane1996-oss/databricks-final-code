# AWS Secrets Manager resource to store workspace URL and PAT
# This is created automatically after workspace is created
# Only created if use_secrets_manager is true
# The secret is automatically updated when workspace_pat is provided in terraform.tfvars
# NO NEED FOR MANUAL SCRIPT - Just provide workspace_pat in terraform.tfvars for Pass-2

resource "aws_secretsmanager_secret" "databricks_workspace" {
  count = var.use_secrets_manager ? 1 : 0
  
  name        = "${var.product_name}-${var.environment}-${var.region}-databricks-workspace"
  description = "Databricks workspace URL and PAT for ${var.product_name}-${var.environment}"
  
  tags = merge(
    local.common_tags,
    {
      component = "secrets-manager"
      purpose   = "databricks-workspace-credentials"
    }
  )
}

# Local to determine the PAT value to store
# Priority: workspace_pat_override > workspace_pat > existing secret value (from data-secrets.tf) > placeholder
locals {
  # Get existing PAT from the data source in data-secrets.tf (if available)
  # This avoids circular dependency by using the existing data source
  existing_pat_from_secret = var.use_secrets_manager && length(data.aws_secretsmanager_secret_version.databricks_workspace) > 0 ? try(
    jsondecode(data.aws_secretsmanager_secret_version.databricks_workspace[0].secret_string).workspace_pat,
    null
  ) : null
  
  # Determine which PAT to store
  # Use override if provided, otherwise use variable, otherwise keep existing (if valid), otherwise placeholder
  pat_to_store = coalesce(
    var.workspace_pat_override,
    var.workspace_pat,
    local.existing_pat_from_secret != null && local.existing_pat_from_secret != "MANUAL_UPDATE_REQUIRED" ? local.existing_pat_from_secret : null,
    "MANUAL_UPDATE_REQUIRED"
  )
  
  # Preserve created_at from existing secret if available, otherwise use current timestamp
  secret_created_at = var.use_secrets_manager && length(data.aws_secretsmanager_secret_version.databricks_workspace) > 0 ? try(
    jsondecode(data.aws_secretsmanager_secret_version.databricks_workspace[0].secret_string).created_at,
    timestamp()
  ) : timestamp()
}

resource "aws_secretsmanager_secret_version" "databricks_workspace" {
  count = var.use_secrets_manager ? 1 : 0
  
  secret_id = aws_secretsmanager_secret.databricks_workspace[0].id
  
  secret_string = jsonencode({
    workspace_id  = module.workspace.workspace_id
    workspace_url = module.workspace.workspace_url
    workspace_pat = local.pat_to_store
    created_at    = local.secret_created_at
    updated_at     = timestamp()
  })
  
  # Only create/update after workspace is created
  depends_on = [module.workspace]
  
  # Terraform automatically detects changes to secret_string (when local.pat_to_store changes)
  # When workspace_pat or workspace_pat_override changes, local.pat_to_store changes,
  # which causes secret_string to change, which triggers an automatic update
  # No need for replace_triggered_by or manual script - just provide workspace_pat in terraform.tfvars
}
