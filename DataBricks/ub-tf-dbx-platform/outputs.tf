output "s3_bucket_name" {
  value       = module.ub_tf_aws_s3.bucket_id
  description = "Shared artifacts/logs S3 bucket"
}

output "workspace_id" {
  value       = module.workspace.workspace_id
  description = "Databricks workspace ID"
}

output "workspace_url" {
  value       = module.workspace.workspace_url
  description = "Databricks workspace URL"
}

output "metastore_id" {
  value       = var.create_metastore ? module.unitycatalog[0].metastore_id : var.shared_metastore_id
  description = "Databricks Unity Catalog metastore ID (created new or shared from another environment)"
}

output "cluster_ids" {
  value = {
    for k, v in module.cluster :
    k => v.cluster_id
  }
  description = "Map of Databricks cluster IDs"
}

output "catalog_names" {
  value = {
    for k, v in module.catalog :
    k => v.catalog_name
  }
  description = "Map of created catalog names"
}
