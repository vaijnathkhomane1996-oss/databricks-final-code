

# No provider blocks here.
module "ub-tf-aws-workspace" {
  source = "git::https://github.com/databricks/terraform-databricks-examples.git//modules/aws-databricks-workspace?ref=v0.2.28"

  # Map product_name to project, environment to env for official module
  project = coalesce(var.project, var.product_name)
  env     = coalesce(var.env, var.environment)
  region  = var.region

  root_storage_bucket   = var.root_storage_bucket
  cross_account_role_arn = var.cross_account_role_arn
  security_group_ids    = var.security_group_ids
  vpc_id                = var.vpc_id
  vpc_private_subnets   = var.vpc_private_subnets
  databricks_account_id = var.databricks_account_id
  
  # MWS Configuration (optional - pass if provided)
  credentials_id             = var.credentials_id
  storage_configuration_id   = var.storage_configuration_id
  network_id                 = var.network_id
  private_access_settings_id = var.private_access_settings_id
  
  workspace_name  = coalesce(var.workspace_name, "${var.product_name}-dashboard-${var.environment}-${var.region}-workspace")
  deployment_name = var.deployment_name
  pricing_tier    = var.pricing_tier
  tags            = var.tags
  prefix          = var.prefix
}
