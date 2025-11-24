# Databricks AWS Workspace Terraform Module

## Overview
This module provisions an AWS-hosted Databricks Workspace using pre-created MWS (Account Console) objects such as credentials, storage configuration, network, and private access settings. It provides a best-practice and repeatable way to create workspaces for various environments using strong tagging, naming consistency, and customizable deployment options.

- Integrates directly with the official Databricks module in their GitHub terraform-databricks-examples repo.
- Enforces usage of mandatory tags (`owner`, `project`, `env`).
- Intended for multi-stage pipelines, large orgs, and cloud automation.

## Features
- Creates and configures a Databricks workspace using MWS objects you provide.
- Automatically names workspace and deployment using your `project` and `env`, unless you specify overrides.
- Tags all resources with required keys for compliance and cost tracking.
- Outputs both the workspace ID and URL for downstream use in pipelines.

## Prerequisites
- You must have all required Account Console objects created in your AWS Databricks account:
  - Credentials
  - Storage configuration
  - Network
  - Private access settings
- Terraform >= 1.6.x
- Databricks Terraform Provider >= 1.51.x

## Input Variables
| Name                      | Type         | Description                                         | Required/Default    |
|---------------------------|--------------|-----------------------------------------------------|---------------------|
| project                   | string       | Project/product name.                               | required            |
| env                       | string       | Environment name: integration, staging, prod, etc.   | required            |
| region                    | string       | AWS region for deployment.                          | required            |
| tags                      | map(string)  | Must include: owner, project, env.                   | required            |
| databricks_account_id     | string       | Databricks Account ID.                              | required            |
| credentials_id            | string       | MWS credentials ID.                                 | required            |
| storage_configuration_id  | string       | MWS storage config ID.                              | required            |
| network_id                | string       | MWS network ID.                                     | required            |
| private_access_settings_id| string       | MWS private access settings ID.                      | required            |
| workspace_name            | string       | Explicit workspace name (optional).                  | default: null       |
| deployment_name           | string       | Deployment name (optional).                          | default: null       |
| pricing_tier              | string       | One of: standard, premium, enterprise.               | default: premium    |

**Mandatory tags (`tags` map):** Your input must include the following keys for validation to pass: `owner`, `project`, `env`.

## Outputs
| Name           | Description                   |
|----------------|------------------------------|
| workspace_id   | Databricks workspace ID.     |
| workspace_url  | Databricks workspace URL.    |

## Usage Example
```hcl
module "workspace" {
  source                     = "git::https://github.com/databricks/terraform-databricks-examples.git//modules/aws-workspace?ref=main"
  project                    = var.project
  env                        = var.env
  region                     = var.region
  tags                       = var.tags
  databricks_account_id      = var.databricks_account_id
  credentials_id             = var.credentials_id
  storage_configuration_id   = var.storage_configuration_id
  network_id                 = var.network_id
  private_access_settings_id = var.private_access_settings_id
  workspace_name             = var.workspace_name # optional
  deployment_name            = var.deployment_name # optional
  pricing_tier               = var.pricing_tier # optional
}
```

## Using the Provided Example
1. Copy `examples/samples/terraform.tfvars.example` to `terraform.tfvars` and fill in the required values (get MWS IDs, tags, region, etc. from your AWS/Databricks admin).
2. Adjust `providers.tf` in your example to include authentication for your account.
3. Run:
```sh
terraform init
terraform apply
```
Output will include `workspace_id` and `workspace_url`.

## Tips
- Ensure all MWS objects are pre-created and their IDs are available.
- If tagging validation fails, double-check all required keys are present and correct in your `tags` map.
- For org-level automation, fork and extend this module to include workspace-level initial provisioning if needed.

## File Structure
- `main.tf`       — Instantiates the remote workspace module and passes down all configuration.
- `variables.tf`  — Input variables and validation logic.
- `outputs.tf`    — Output values such as workspace ID/URL.
- `versions.tf`   — Minimum required Terraform/provider versions.
- `examples/`     — Self-contained example for unit/real testing and developer onboarding.

---
For full documentation, see the official Databricks Terraform examples repo: https://github.com/databricks/terraform-databricks-examples
