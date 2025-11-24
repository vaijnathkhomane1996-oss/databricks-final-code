
# No provider blocks here.
# Provider is passed from the calling module
module "ub-tf-aws-cluster" {
  source = "git::https://github.com/databricks/terraform-databricks-examples.git//modules/databricks-department-clusters?ref=v0.2.28"
  
  # Use provided cluster_name instead of auto-generating
  cluster_name  = var.cluster_name
  
  # Cluster configuration - only pass if provided (underlying module may not support all)
  # Using try() to make them optional and avoid errors if module doesn't accept them
  spark_version = try(var.spark_version, null)
  node_type_id  = try(var.node_type_id, null)
  num_workers   = try(var.num_workers, null)
  
  # Workspace authentication
  workspace_url = var.workspace_url
  workspace_pat = var.workspace_pat
  
  # Required by underlying module
  tags       = var.tags
  department = var.department
  group_name = var.group_name
  
  # Note: project and env are not passed as underlying module may not need them
  # If underlying module requires them, uncomment below:
  # project = var.project
  # env     = var.env
}

