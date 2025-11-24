module "dbx_platform" {
  # Repo B root module – adjust path or use git source if needed
  source = "git::https://github.com/<org>/ub-tf-dbx-platform.git?ref=<tag>"

  # Core Identity
  product_name = var.product_name
  service      = local.service
  environment  = local.environment
  region       = var.region

  # Databricks Account / MWS
  databricks_account_id          = var.databricks_account_id
  mws_credentials_id             = var.mws_credentials_id
  mws_storage_config_id          = var.mws_storage_config_id
  mws_network_id                 = var.mws_network_id
  mws_private_access_settings_id = var.mws_private_access_settings_id

  # Unity Catalog Required Variables (for shared metastore)
  aws_account_id        = var.aws_account_id
  unity_metastore_owner = var.unity_metastore_owner
  prefix                = local.prefix

  # Shared Metastore Configuration (use staging metastore)
  shared_metastore_id = var.shared_metastore_id
  create_metastore   = false

  # Existing VPC
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  security_group_ids = var.security_group_ids

  # Workspace Storage Configuration (Required by Repo A)
  root_storage_bucket   = var.root_storage_bucket
  cross_account_role_arn = var.cross_account_role_arn

  # Secrets Manager Configuration
  workspace_pat         = var.workspace_pat
  use_secrets_manager   = var.use_secrets_manager
  workspace_pat_override = var.workspace_pat_override
  workspace_url_override = var.workspace_url_override

  # Tags + workspace (UC + clusters + catalogs)
  tags      = local.tags
  workspace = local.workspace
}
