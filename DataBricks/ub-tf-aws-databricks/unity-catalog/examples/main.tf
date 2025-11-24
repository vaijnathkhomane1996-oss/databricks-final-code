locals {
  name_prefix = "${var.project}-${var.env}"
}

# Retrieve Databricks password from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "dbx_pwd" {
  secret_id = var.databricks_secret_name
}

locals {
  databricks_password = data.aws_secretsmanager_secret_version.dbx_pwd.secret_string
}

module "ub-tf-aws-unity-catalog" {
  source = "../../../modules/unity-catalog"  # points to modules/unity-catalog from this examples folder

  # REQUIRED by the submodule
  databricks_account_id = "placeholder" # kept for interface compatibility
  workspace_id          = var.workspace_id

  metastore_name   = var.metastore_name
  metastore_region = var.metastore_region

  uc_external_bucket  = var.uc_external_bucket
  uc_external_prefix  = var.uc_external_prefix
  uc_storage_role_arn = var.uc_storage_role_arn

  # Mandatory tags (must include: owner, env, product, service, repo, created_by, customer, region.)
  tags = var.tags
}


