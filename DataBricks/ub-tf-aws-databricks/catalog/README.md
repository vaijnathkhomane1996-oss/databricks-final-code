# Databricks Unity Catalog Terraform Module

## Overview
This module provisions a Unity Catalog catalog inside an existing Databricks workspace. It is designed to be a reusable, configurable, and standards-compliant way to create catalogs with mandatory tagging, consistency in naming, and cloud-agnostic provider support.

- **No provider blocks are defined in the root module** — pass providers from your usage layer.
- Most parameters including storage root, grants, and tags are customizable.
- Intended for use in organizational folder structures where workspace-level and catalog-level configurations are separated.

## Features
- Creates a single Unity Catalog catalog based on inputs.
- Sets standard tags and naming patterns.
- Flexible for dev, staging, or prod environments.
- Supports catalog-level grants for access control.
- Can be included in larger automation pipelines or used stand-alone via the provided example.

## Prerequisites
- An existing Databricks workspace with Unity Catalog enabled.
- A Personal Access Token (PAT) with catalog creation privileges.
- Unity Catalog metastore must be assigned to the workspace.
- Terraform >= 1.6.x
- Databricks Terraform Provider >= 1.51.x

## Input Variables

| Name         | Type         | Description                                                               | Required/Default |
|--------------|--------------|---------------------------------------------------------------------------|------------------|
| workspace_url | string       | Databricks workspace URL. Example: `https://adb-XXXX.cloud.databricks.com` | required         |
| workspace_pat | string       | Databricks workspace Personal Access Token                                 | required         |
| name         | string       | Name of the Unity Catalog catalog                                          | required         |
| storage_root | string       | Storage root for managed tables (e.g., `s3://bucket-name/path/`)            | required         |
| comment      | string       | Optional comment/description for the catalog                               | default: null    |
| grants       | list(object) | List of grants to apply on the catalog                                     | default: []      |
| tags         | map(string)  | Tags applied to all catalog resources (must not be empty)                  | required         |

### Grants Structure
```hcl
grants = [
  {
    principal  = "data-engineers"  # Group or user name
    privileges = ["USE_CATALOG"]   # List of privileges
  }
]
```

Common privileges:
- `USE_CATALOG` - Allow use of the catalog
- `CREATE_SCHEMA` - Allow schema creation (if needed)

*See `variables.tf` for validation specifics*

## Outputs

| Name         | Description                                  |
|--------------|----------------------------------------------|
| catalog_name | The name of the created Unity Catalog catalog |

## How to Use
### Direct Usage Example
```hcl
provider "databricks" {
  host  = var.workspace_url
  token = var.workspace_pat
}

module "catalog" {
  source        = "git::<repo_url>//catalog"
  workspace_url = var.workspace_url
  workspace_pat = var.workspace_pat
  name          = var.catalog_name
  storage_root  = "s3://my-bucket/catalogs/my_catalog/"
  comment       = "My Unity Catalog catalog"
  grants        = var.grants
  tags          = var.tags
  providers     = { databricks = databricks }
}
```

### Using the Example
1. Copy `examples/terraform.tfvars.example` to `terraform.tfvars` and fill in your values.
2. Ensure your PAT and workspace are valid.
3. Ensure Unity Catalog is enabled and metastore is assigned to your workspace.
4. Run:
```sh
cd examples
terraform init
terraform apply
```
The example will provision a catalog using the module. Output will include the catalog's name.

## Tips
- Always use secure methods or state management for your PAT.
- Storage root should point to a valid S3 bucket path (or equivalent for your cloud).
- Catalog names must be unique within a metastore.
- Grants are applied at the catalog level; schema-level grants are separate.
- You can extend this module by forking and adding additional features.

## File Structure
- `main.tf`       — Module logic and catalog resource creation.
- `variables.tf`  — Input variable declarations and validation.
- `output.tf`     — Exported values from the catalog module.
- `examples/`     — Complete usage demo for fast starts and CI/CD testing.

---
For questions or improvements, open an issue or PR on the hosting repository.

