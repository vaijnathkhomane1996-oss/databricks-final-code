#############################################
# Shared S3 Bucket
#############################################

module "ub_tf_aws_s3" {
  source = "git::https://github.com/urbint/ub-tf-aws-s3.git?ref=<release-tag>"

  bucket_name        = local.s3_bucket_resource_name
  environment        = var.environment
  versioning_enabled = true

  tags = local.s3_tags
}

#############################################
# Workspace
#############################################

module "workspace" {
  source = "git::https://github.com/<org>/ub-tf-aws-databricks.git//workspace?ref=<tag>"
  
  # Core identity
  product_name = var.product_name
  environment  = var.environment
  region       = var.region
  
  # Databricks Account / MWS
  databricks_account_id = var.databricks_account_id
  credentials_id        = var.mws_credentials_id
  storage_configuration_id   = var.mws_storage_config_id
  network_id                 = var.mws_network_id
  private_access_settings_id = var.mws_private_access_settings_id

  # Workspace configuration
  workspace_name = var.workspace.workspace_name
  pricing_tier   = var.workspace.pricing_tier
  prefix         = var.prefix

  # VPC configuration
  vpc_id                = var.vpc_id
  vpc_private_subnets   = var.private_subnet_ids
  security_group_ids    = var.security_group_ids

  # Required by Repo A workspace module
  root_storage_bucket   = var.root_storage_bucket
  cross_account_role_arn = var.cross_account_role_arn

  # Tags
  tags = local.common_tags
}

#############################################
# Unity Catalog
#############################################
# Conditionally create new metastore OR assign existing shared metastore

module "unitycatalog" {
  count = var.create_metastore ? 1 : 0
  
  source = "git::https://github.com/<org>/ub-tf-aws-databricks.git//unity-catalog?ref=<tag>"

  # Required by Repo A
  databricks_account_id = var.databricks_account_id
  workspace_id          = module.workspace.workspace_id
  metastore_name        = var.workspace.uc_metastore_name
  metastore_region      = var.workspace.uc_metastore_region

  # Additional required variables
  aws_account_id        = var.aws_account_id
  unity_metastore_owner = var.unity_metastore_owner
  prefix                = var.prefix

  # Optional variables (if Repo A supports them)
  uc_external_bucket   = try(var.workspace.uc_external_bucket, null)
  uc_external_prefix   = try(var.workspace.uc_external_prefix, null)
  uc_storage_role_arn  = try(var.workspace.uc_storage_role_arn, null)

  # Tags
  tags = local.common_tags

  # Unity Catalog uses AWS provider (MWS API), not databricks provider
  # No providers block needed here
}

# Assign existing shared metastore to workspace (when create_metastore = false)
# Note: This requires databricks provider, which is only available after workspace is created
# The assignment will happen in Pass-2 after PAT is stored (same as clusters/catalogs)


resource "databricks_metastore_assignment" "shared_metastore" {
  count = var.create_metastore == false && var.shared_metastore_id != null && local.workspace_url != null && local.workspace_pat != null ? 1 : 0
  
  workspace_id         = module.workspace.workspace_id
  metastore_id         = var.shared_metastore_id
  default_catalog_name = "hive_metastore"
  
  # Use databricks provider for workspace-scoped operations
  # Provider is configured via alias, but default provider is also available
  depends_on = [module.workspace]
}

#############################################
# Catalog
#############################################
# Only create catalogs if workspace_url and workspace_pat are available (Pass-2)
# During Pass-1, these will be null and catalogs will be skipped

module "catalog" {
  for_each = local.workspace_url != null && local.workspace_pat != null ? var.workspace.catalogs : {}

  source = "git::https://github.com/<org>/ub-tf-aws-databricks.git//catalog?ref=<tag>"

  # Catalog configuration
  name         = each.key
  storage_root = each.value.storage_root
  comment      = null  # Optional, can be added later if needed
  grants       = try(each.value.grants, [])

  # Tags
  tags = merge(
    local.common_tags,
    {
      component    = "databricks-catalog"
      catalog_name = each.key
    }
  )

  # Force this module to use the databricks provider
  providers = {
    databricks = databricks.workspace
  }
  
  # IMPORTANT: Catalogs are created in the metastore assigned to the workspace
  # If using shared metastore (create_metastore = false), ensure metastore is assigned first
  # Catalogs will be created in the staging metastore when integration workspace uses it
  depends_on = [
    module.workspace,
    databricks_metastore_assignment.shared_metastore
  ]
}

#############################################
# Clusters — multiple clusters
#############################################
# Only create clusters if workspace_url and workspace_pat are available (Pass-2)
# During Pass-1, these will be null and clusters will be skipped

module "cluster" {
  for_each = local.workspace_url != null && local.workspace_pat != null ? var.workspace.clusters : {}

  source = "git::https://github.com/<org>/ub-tf-aws-databricks.git//cluster?ref=<tag>"

  # Workspace authentication
  workspace_url = local.workspace_url
  workspace_pat = local.workspace_pat

  # Cluster configuration
  cluster_name  = each.value.cluster_name
  spark_version = each.value.spark_version
  node_type_id  = each.value.node_type_id
  num_workers   = each.value.num_workers

  # Required by Repo A
  project       = var.product_name  # Map product_name to project
  env           = var.environment   # Map environment to env
  department    = "data-platform"   # Default department
  group_name    = "databricks-team"  # Default group name

  # Tags (includes product_name, environment, region via tags)
  tags = merge(
    local.common_tags,
    {
      component    = "databricks-cluster"
      cluster_name = each.value.cluster_name
    }
  )

  # Force this module to use the databricks provider
  providers = {
    databricks = databricks.workspace
  }
}
