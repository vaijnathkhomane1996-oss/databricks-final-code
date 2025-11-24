# AWS Provider - Used for workspace and Unity Catalog creation
provider "aws" {
  region = var.region
  # Credentials from AWS CLI, environment variables, or IAM role
}

# Databricks Provider (aliased) - Used for cluster and catalog operations
# Using alias to avoid circular dependency issues
# The provider will be configured with workspace_url after workspace is created
# Will automatically retrieve from Secrets Manager if not provided
provider "databricks" {
  alias = "workspace"
  host  = local.workspace_url
  token = local.workspace_pat
}

# Databricks Provider (default) - Used for metastore assignment and other workspace operations
# Same configuration as aliased provider, but available as default for resources that don't specify provider
provider "databricks" {
  host  = local.workspace_url
  token = local.workspace_pat
}

