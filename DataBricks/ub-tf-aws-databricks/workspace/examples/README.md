# Example: Databricks Workspace Deployment

This example demonstrates usage of the workspace Terraform module to provision an AWS Databricks workspace using existing Account Console (MWS) infrastructure objects.

## What it Does
- Creates a workspace
- Names and tags it using the required tags (`owner`, `project`, `env`)
- Outputs both the workspace ID and URL for convenience

## How to Run
1. **Prepare Inputs:**
   - Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in all placeholder values:
     - All MWS/Account Console object IDs and credentials
     - Project/environment/region and valid tags
2. **Provider Auth:** Edit `providers.tf` (if needed) with correct basic auth for your Databricks account.
3. **Apply:**
   ```sh
   terraform init
   terraform apply
   ```
4. **Output:** On success, you’ll see the new workspace's ID and URL printed in the Terraform output.

## Tips
- Make sure all IDs (credentials, storage, network, private access) exist and are correct.
- Errors about tags mean your `tags` map is missing `owner`, `project`, or `env`.
- You can use this as a template and adapt for other environments (dev, staging, prod, etc.).

---
For more details and options, see the parent module's [README](../../README.md).
