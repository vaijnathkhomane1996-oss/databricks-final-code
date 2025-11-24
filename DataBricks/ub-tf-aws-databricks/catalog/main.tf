resource "databricks_catalog" "this" {
  name         = var.name
  comment      = var.comment
  storage_root = var.storage_root
}

# Grants on the catalog itself
resource "databricks_grants" "catalog" {
  catalog = databricks_catalog.this.name
  tags          = var.tags

  dynamic "grant" {
    for_each = var.grants
    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}
