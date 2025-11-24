provider "aws" {
  region = var.region
}

# Note: Repo B manages its own Databricks provider configuration internally
# No need to define Databricks provider here - Repo B handles it via Secrets Manager
