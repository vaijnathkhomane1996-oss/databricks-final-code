# Retrieve Databricks password from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "dbx_pwd" {
  secret_id = var.databricks_secret_name
}

locals {
  databricks_password = data.aws_secretsmanager_secret_version.dbx_pwd.secret_string
}

module "ub-tf-aws-workspace" {
  source = "../../../modules/workspace"

  project  = var.project
  env      = var.env
  region   = var.region
  tags     = var.tags

  databricks_account_id      = var.databricks_account_id
  credentials_id             = var.credentials_id
  storage_configuration_id   = var.storage_configuration_id
  network_id                 = var.network_id
  private_access_settings_id = var.private_access_settings_id

  workspace_name  = var.workspace_name
  deployment_name = var.deployment_name
  pricing_tier    = var.pricing_tier
}
