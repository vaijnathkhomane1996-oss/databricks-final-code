# Unity Catalog Example: Simple Deployment

This example demonstrates how to use the `unity-catalog` module to provision an AWS Databricks Unity Catalog metastore and set up the required infrastructure, such as S3 external locations and IAM roles.

## Steps to Run
1. **Copy and configure variables:**
   - Duplicate `terraform.tfvars.example` to `terraform.tfvars`, then update values to reflect your environment:
     - Fill in your Databricks workspace/account identifiers
     - Set the S3 bucket and IAM role for Unity Catalog
     - Fill in tags (must include `owner`, `project`, `env`)

2. **Set up the provider:**
   - Edit `provider.tf` with a valid workspace URL and PAT.

3. **Run Terraform:**
   - From this directory, run:
     ```sh
     terraform init
     terraform apply
     ```
   - On success, output includes the Unity Catalog metastore's ID.

## Notes
- This example assumes all infrastructure prerequisites (IAM roles, buckets) are already in place and properly permissioned for Databricks.
- Refer to the parent module's [README](../../README.md) for detailed variable, output, and module behavior documentation.

---
For further customization, use this example as a template and adjust variables or structure as needed for your own deployments.
