# Account Console (MWS) provider (basic auth)
provider "databricks" {
  alias      = "mws"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
  username   = var.databricks_username
  password   = var.databricks_password
}
