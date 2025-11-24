locals {
  # Auto-compute service (always databricks)
  service = "databricks"
  
  # Auto-compute environment (from folder name)
  environment = "intg"
  
  # Auto-compute S3 bucket name
  s3_bucket_name = "${var.product_name}-dashboard-${local.environment}-${var.region}"
  
  # Auto-compute workspace name if not provided
  workspace_name = try(var.workspace.workspace_name, "${var.product_name}-${local.environment}-ws-${var.region}")
  
  # Auto-compute metastore name (references staging metastore)
  uc_metastore_name = try(var.workspace.uc_metastore_name, "${var.product_name}-stag-metastore-${var.region}")
  
  # Auto-compute metastore region (use same as region)
  uc_metastore_region = try(var.workspace.uc_metastore_region, var.region)
  
  # Auto-compute UC external prefix (use S3 bucket created during deployment)
  uc_external_prefix = try(var.workspace.uc_external_prefix, "s3://${local.s3_bucket_name}/unity-catalog/")
  
  # Auto-compute prefix from product_name (first 2-3 chars)
  prefix = try(var.prefix, substr(var.product_name, 0, min(3, length(var.product_name))))
  
  # Auto-compute tags
  tags = merge(
    {
      env        = local.environment
      product    = var.product_name
      service    = local.service
      repo       = "ub-tf-dbx-platform"
      created_by = "terraform"
      region     = var.region
    },
    var.tags
  )
  
  # Auto-compute catalog storage roots
  catalogs = {
    for k, v in var.workspace.catalogs : k => {
      storage_root = try(v.storage_root, "s3://${local.s3_bucket_name}/catalogs/${local.environment}/${k}/")
      grants       = try(v.grants, [])
    }
  }
  
  # Build workspace object with computed values
  workspace = {
    workspace_name      = local.workspace_name
    pricing_tier        = var.workspace.pricing_tier
    uc_metastore_name   = local.uc_metastore_name
    uc_metastore_region = local.uc_metastore_region
    uc_external_prefix  = local.uc_external_prefix
    uc_storage_role_arn = var.workspace.uc_storage_role_arn
    clusters            = var.workspace.clusters
    catalogs            = local.catalogs
  }
}

