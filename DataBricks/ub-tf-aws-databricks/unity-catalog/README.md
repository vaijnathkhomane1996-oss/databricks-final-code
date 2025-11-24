# AWS Unity Catalog Terraform Module

## Overview
This module provisions an AWS Databricks Unity Catalog metastore, S3 external location, and all associated configuration bits in a best-practice and reusable way. It acts as a wrapper around the official [terraform-databricks-examples](https://github.com/databricks/terraform-databricks-examples) remote Unity Catalog module for AWS.

- Uses and strictly enforces key tags (owner, project, env) for visibility and management.
- Supports workspace-scoped and account-scoped Databricks providers.
- Automatically sets up a metastore, S3 bucket location, and role for Unity Catalog operation.
- Intended for use in production deployment pipelines or modular IaC projects.

## Features
- Orchestrates all major Unity Catalog AWS resources with a single module invocation.
- Supply your own S3 bucket and IAM role for best security and compliance.
- Optionally bootstrap catalogs and schemas via upstream module.
- Outputs the created metastore ID for further automation.

## Prerequisites
- AWS Databricks workspace and account.
- S3 bucket and IAM Role created for Unity Catalog access.
- Terraform >= 1.5.x
- Databricks Terraform Provider >= 1.39.x

## Input Variables
| Name                   | Type         | Description                                               | Required/Default        |
|------------------------|--------------|-----------------------------------------------------------|-------------------------|
| databricks_account_id  | string       | Databricks Account (MWS) ID.                              | required                |
| workspace_id           | string       | Databricks workspace ID to assign the metastore to.       | required                |
| metastore_name         | string       | Unity Catalog metastore name.                             | required (not empty)    |
| metastore_region       | string       | AWS region where the catalog will be deployed.            | required (e.g. us-east-2)|
| uc_external_bucket     | string       | S3 bucket used for the Unity Catalog external location.   | required (not empty)    |
| uc_external_prefix     | string       | (Optional) Folder prefix in S3 bucket.                    | default: ""             |
| uc_storage_role_arn    | string       | IAM role ARN for the Unity Catalog external location.     | required                |
| tags                   | map(string)  | Must include keys: owner, project, env.                   | required, cannot be empty|

(See `variables.tf` for details/validation.)

## Outputs
| Name         | Description                                |
|--------------|--------------------------------------------|
| metastore_id | The ID of the provisioned Unity Catalog metastore |

## How to Use
### Direct Usage Example
```hcl
provider "databricks" {
  host  = var.workspace_url  # e.g., https://adb-xxxx.cloud.databricks.com
  token = var.workspace_pat
}

module "unity_catalog" {
  source                = "git::https://github.com/databricks/terraform-databricks-examples.git//modules/aws-unity-catalog?ref=main"
  databricks_account_id = var.databricks_account_id
  workspace_id          = var.workspace_id
  metastore_name        = var.metastore_name
  metastore_region      = var.metastore_region
  uc_external_bucket    = var.uc_external_bucket
  uc_external_prefix    = var.uc_external_prefix
  uc_storage_role_arn   = var.uc_storage_role_arn
  tags                  = var.tags
}
```

### Using the Provided Example
Under `examples/simple` you’ll find a runnable Terraform example.
1. Copy `terraform.tfvars.example` to `terraform.tfvars` and edit values as appropriate for your environment (workspaces, buckets, ARNs, etc.).
2. Make sure the provider in `provider.tf` is updated with your workspace PAT and URL.
3. Run the following inside `examples/simple`:
```sh
terraform init
terraform apply
```
On completion, the output will include the new metastore's ID and any additional outputs as returned by the underlying module.

## Tips
- IAM roles and S3 buckets must have appropriate permissions for Databricks Unity Catalog.
- PAT tokens should be kept secret, using environment variables or a secure vault system if possible.
- All tags (owner, project, env) are required for compliance and automation.

## File Structure
- `main.tf`       — Pass-through source to the remote module, passing all declared variables.
- `variables.tf`  — Inputs for this orchestration module (mirrored from the remote module).
- `outputs.tf`    — Outputs from the upstream Databricks AWS Unity Catalog module.
- `versions.tf`   — Sets the minimum Terraform/Provider versions.
- `examples/`     — A pre-configured, ready-to-tweak usage example.

---
For more details, see the upstream [terraform-databricks-examples](https://github.com/databricks/terraform-databricks-examples/blob/main/modules/aws-unity-catalog/README.md) documentation.
