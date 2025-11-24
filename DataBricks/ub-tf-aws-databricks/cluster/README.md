# Databricks Cluster Terraform Module

## Overview
This module provisions a shared or department Databricks cluster inside an existing Databricks workspace. It is designed to be a reusable, configurable, and standards-compliant way to create clusters with mandatory tagging, consistency in naming, and cloud-agnostic provider support.

- **No provider blocks are defined in the root module** — pass providers from your usage layer.
- Most parameters including runtime, type, and tags are customizable.
- Intended for use in organizational folder structures where workspace-level and cluster-level configurations are separated.

## Features
- Creates a single Databricks cluster based on inputs.
- Sets standard tags and naming patterns.
- Flexible for dev, staging, or prod environments.
- Can be included in larger automation pipelines or used stand-alone via the provided example.

## Prerequisites
- An existing Databricks workspace and of course a Personal Access Token (PAT) with cluster creation privileges.
- Terraform >= 1.6.x
- Databricks Terraform Provider >= 1.51.x

## Input Variables

| Name            | Type         | Description                                                               | Required/Default |
|-----------------|--------------|---------------------------------------------------------------------------|------------------|
| workspace_url   | string       | Databricks workspace URL. Example: `https://adb-XXXX.cloud.databricks.com` | required         |
| workspace_pat   | string       | Databricks workspace Personal Access Token                                 | required         |
| project         | string       | Project name for naming and resource tagging                               | required         |
| env             | string       | Environment name: `dev`, `staging`, or `prod`                              | required         |
| cluster_name    | string       | Override for cluster name, optional (auto-generated if omitted)            | required         |
| spark_version   | string       | Databricks runtime version string                                          | required         |
| node_type_id    | string       | Instance type for Databricks worker nodes                                  | required         |
| num_workers     | number       | Number of worker nodes in the cluster                                      | default: 2       |
| tags            | map(string)  | Tags applied to all cluster resources (must not be empty)                  | required         |

*See `variables.tf` for validation specifics*

## Outputs

| Name       | Description                                  |
|------------|----------------------------------------------|
| cluster_id | The ID of the created Databricks cluster     |

## How to Use
### Direct Usage Example
```hcl
provider "databricks" {
  host  = var.workspace_url
  token = var.workspace_pat
}

module "cluster" {
  source        = "git::<repo_url>//modules/cluster"
  workspace_url = var.workspace_url
  workspace_pat = var.workspace_pat
  project       = var.project
  env           = var.env
  cluster_name  = var.cluster_name
  spark_version = var.spark_version
  node_type_id  = var.node_type_id
  num_workers   = var.num_workers
  tags          = var.tags
  providers     = { databricks = databricks }
}
```

### Using the Example
1. Copy `examples/simple/terraform.tfvars.example` to `terraform.tfvars` and fill in your values.
2. Ensure your PAT and workspace are valid.
3. Run:
```sh
cd examples/simple
terraform init
terraform apply
```
The example will provision a cluster using the module. Output will include the cluster's ID.

## Tips
- Always use secure methods or state management for your PAT.
- You can extend this module by forking and adding additional features.

## File Structure
- `main.tf`       — Module logic and cluster resource creation.
- `variables.tf`  — Input variable declarations and validation.
- `outputs.tf`    — Exported values from the cluster module.
- `versions.tf`   — Provider and Terraform version requirements.
- `examples/`     — Complete usage demo for fast starts and CI/CD testing.

---
For questions or improvements, open an issue or PR on the hosting repository.
