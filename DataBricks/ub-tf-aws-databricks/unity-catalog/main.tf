module "ub-tf-aws-unity-catalog" {
  source = "git::https://github.com/databricks/terraform-databricks-examples.git//modules/aws-databricks-unity-catalog?ref=v0.2.28"

  databricks_account_id = var.databricks_account_id
  workspace_id          = var.workspace_id
  metastore_name        = var.metastore_name
  aws_account_id        = var.aws_account_id
  tags                  = var.tags
  unity_metastore_owner = var.unity_metastore_owner
  prefix                = var.prefix
  region                = var.metastore_region
  
  # Optional variables - only pass if provided and underlying module supports them
  # uc_external_bucket, uc_external_prefix, uc_storage_role_arn are handled
  # by the underlying module if needed
}
