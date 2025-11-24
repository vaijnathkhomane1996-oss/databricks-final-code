# Workspace-scoped provider (PAT)
provider "databricks" {
  host  = var.workspace_url
  token = var.workspace_pat
}

