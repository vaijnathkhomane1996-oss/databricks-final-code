output "s3_bucket_name" {
  description = "Shared S3 bucket used by the Databricks platform"
  value       = module.dbx_platform.s3_bucket_name
}

output "workspace_url" {
  description = "Databricks workspace URL"
  value       = module.dbx_platform.workspace_url
}

output "metastore_id" {
  description = "Unity Catalog metastore ID"
  value       = module.dbx_platform.metastore_id
}

output "cluster_ids" {
  description = "Map of cluster IDs keyed by cluster key"
  value       = module.dbx_platform.cluster_ids
}

output "catalog_names" {
  description = "Map of created catalog names"
  value       = module.dbx_platform.catalog_names
}