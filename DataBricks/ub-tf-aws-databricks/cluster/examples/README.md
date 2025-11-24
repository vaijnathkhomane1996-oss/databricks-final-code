# Cluster submodule example

This example creates a shared/department cluster inside an existing Databricks workspace (provider configured here).

## How to run
1. Export/define a workspace-scoped `databricks` provider in `providers.tf`.
2. Fill in `terraform.tfvars` with runtime, node type, workers and tags.
3. `terraform init && terraform apply`.

> The actual submodule (`modules/cluster`) has no provider blocks; providers live only in examples.
