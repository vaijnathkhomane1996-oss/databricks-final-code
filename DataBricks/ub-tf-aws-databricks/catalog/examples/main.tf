module "ub-tf-aws-catalog" {
  source = "../" # points to parent catalog module
  
  # Catalog configuration
  name         = var.name
  storage_root = var.storage_root
  comment      = var.comment
  
  # Grants
  grants = var.grants
  
  # Tags
  tags = var.tags
}

