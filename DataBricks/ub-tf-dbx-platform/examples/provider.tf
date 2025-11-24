provider "aws" {
  region = var.region
  # Credentials from AWS CLI, environment variables, or IAM role
}

# Databricks provider is configured within the root module
# using workspace_pat for cluster and catalog operations
# Workspace creation uses MWS API via AWS provider
