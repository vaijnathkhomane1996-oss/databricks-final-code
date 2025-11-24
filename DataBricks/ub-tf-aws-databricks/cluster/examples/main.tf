module "ub-tf-aws-cluster" {
  source = "../../../modules/cluster" # points to modules/cluster
  workspace_url = var.workspace_url
  workspace_pat = var.workspace_pat
  cluster_name  = var.cluster_name
  tags          = var.tags
  project       = var.project
  env           = var.env
}


