# Workspace-scoped provider (single-pass)
provider "databricks" {
  host  = var.workspace_url
  token = var.workspace_pat
}
