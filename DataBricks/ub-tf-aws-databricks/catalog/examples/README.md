# Catalog submodule example

This example creates a Unity Catalog catalog inside an existing Databricks workspace (provider configured here).

## How to run
1. Export/define a workspace-scoped `databricks` provider in `providers.tf`.
2. Fill in `terraform.tfvars` with catalog name, storage root, grants, and tags.
3. `terraform init && terraform apply`.

> The actual submodule (`catalog`) has no provider blocks; providers live only in examples.

## Example terraform.tfvars

```hcl
workspace_url = "https://adb-1234567890123456.7.databricks.azure.cn"
workspace_pat = "your-personal-access-token"

name         = "my_catalog"
storage_root = "s3://my-bucket/catalogs/my_catalog/"
comment      = "My Unity Catalog catalog"

grants = [
  {
    principal  = "data-engineers"
    privileges = ["USE_CATALOG"]
  }
]

tags = {
  owner      = "data-team"
  env        = "stag"
  product    = "data-platform"
  service    = "databricks"
  repo       = "ub-tf-aws-databricks"
  created_by = "terraform"
  customer   = "internal"
  region     = "us-east-2"
}
```

