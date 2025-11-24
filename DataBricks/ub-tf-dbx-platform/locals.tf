locals {
  ########################################
  # Abbreviations
  ########################################
  s3_abbr  = "s3"
  dbx_abbr = "dbx"
  uc_abbr  = "uc"

  ########################################
  # Naming
  ########################################
  name_prefix = "${var.product_name}-${var.environment}-${var.region}"

  # Shared S3 bucket
  s3_bucket_resource_name = "${var.product_name}-dashboard-${var.environment}-${var.region}"

  # Optional defaults
  workspace_name_default        = "${local.name_prefix}-${local.dbx_abbr}"
  uc_metastore_name_default     = "${local.name_prefix}-${local.uc_abbr}-metastore"
  cluster_name_default_prefix   = "${local.name_prefix}-${local.dbx_abbr}-cluster"

  ########################################
  # Tag sets
  ########################################

  common_tags = merge(
    var.tags,
    {
      name      = local.name_prefix
      component = "databricks-platform"
      product   = var.product_name
      service   = var.service
    }
  )

  s3_tags = merge(
    local.common_tags,
    {
      component = "storage"
      purpose   = "databricks-shared"
    }
  )
}
