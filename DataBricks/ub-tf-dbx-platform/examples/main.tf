module "dbx_platform" {
  # Root module (Repo B) – references the parent directory
  source = "../"

  # Core identity
  product_name = var.product_name
  service      = var.service
  environment  = var.environment
  region       = var.region

  # Databricks Account / MWS IDs
  databricks_account_id          = var.databricks_account_id
  mws_credentials_id             = var.mws_credentials_id
  mws_storage_config_id          = var.mws_storage_config_id
  mws_network_id                 = var.mws_network_id
  mws_private_access_settings_id = var.mws_private_access_settings_id

  # Workspace Authentication
  workspace_pat         = var.workspace_pat
  workspace_pat_override = var.workspace_pat_override
  workspace_url_override = var.workspace_url_override
  use_secrets_manager   = var.use_secrets_manager

  # Unity Catalog Required Variables
  aws_account_id        = var.aws_account_id
  unity_metastore_owner = var.unity_metastore_owner
  prefix                = var.prefix

  # Existing VPC
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  security_group_ids = var.security_group_ids

  # Tags + workspace (UC + clusters + catalogs)
  tags      = var.tags
  workspace = var.workspace
}
