output "workspace_id" {
  description = "Databricks workspace ID."
  value       = module.ub-tf-aws-workspace.workspace_id
}

output "workspace_url" {
  description = "Databricks workspace URL."
  value       = module.ub-tf-aws-workspace.workspace_url
}
