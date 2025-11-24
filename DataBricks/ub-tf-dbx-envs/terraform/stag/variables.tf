########################################
# Identity
########################################

variable "region" {
  description = "AWS region (e.g. us-east-2)"
  type        = string
}

variable "product_name" {
  description = "Product name (e.g. damage-prevention)"
  type        = string
}

variable "service" {
  description = "Service name (e.g. databricks)"
  type        = string
  default     = "databricks"
}

variable "environment" {
  description = "Environment (intg, stag, prod, demo)"
  type        = string
  default     = "stag"
}

# Note: databricks_host and databricks_token are not needed here
# Repo B manages Databricks provider configuration internally via Secrets Manager

########################################
# Databricks Account / MWS IDs
########################################

variable "databricks_account_id" {
  description = "Databricks Account ID (MWS / Accounts API)"
  type        = string
}

variable "mws_credentials_id" {
  description = "MWS credentials object ID"
  type        = string
}

variable "mws_storage_config_id" {
  description = "MWS storage configuration object ID"
  type        = string
}

variable "mws_network_id" {
  description = "MWS network object ID"
  type        = string
}

variable "mws_private_access_settings_id" {
  description = "MWS private access settings object ID"
  type        = string
}

########################################
# Existing VPC
########################################

variable "vpc_id" {
  description = "Existing VPC ID to attach the Databricks workspace to"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Databricks compute"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for Databricks workspace/compute"
  type        = list(string)
}

########################################
# Workspace Storage Configuration (Required by Repo A)
########################################

variable "root_storage_bucket" {
  description = "S3 bucket name used as root storage bucket for Databricks workspace"
  type        = string
}

variable "cross_account_role_arn" {
  description = "IAM role ARN used for cross-account access (required for Databricks workspace)"
  type        = string
}

########################################
# Corporate tags (validated inside Repo B)
########################################

variable "tags" {
  description = "Additional tags (owner, customer are required; env, product, service, repo, created_by, region are auto-computed)"
  type        = map(string)
  default     = {}
}

########################################
# Workspace + UC + Multiple Clusters + Multiple Catalogs
########################################

variable "workspace" {
  description = "Workspace + Unity Catalog + clusters + catalogs configuration"

  type = object({
    # Workspace
    workspace_name = optional(string)  # Auto-computed if not provided
    pricing_tier   = string

    # Unity Catalog
    uc_metastore_name   = optional(string)  # Auto-computed if not provided
    uc_metastore_region = optional(string)  # Auto-computed from region if not provided
    uc_external_prefix  = optional(string)  # Auto-computed from S3 bucket if not provided
    uc_storage_role_arn = string

    # Clusters (3 clusters per environment)
    clusters = map(object({
      cluster_name  = string
      spark_version = string
      node_type_id  = string
      num_workers   = number
    }))

    # Catalogs (3 catalogs per environment)
    catalogs = map(object({
      storage_root = optional(string)  # Auto-computed from S3 bucket if not provided
      grants = optional(list(object({
        principal  = string
        privileges = list(string)
      })), [])
    }))
  })
}

########################################
# Unity Catalog Required Variables (for shared metastore)
########################################

variable "aws_account_id" {
  type        = string
  sensitive   = true
  description = "AWS account ID (required for Unity Catalog)"
}

variable "unity_metastore_owner" {
  type        = string
  sensitive   = true
  description = "Unity Catalog metastore owner (required for Unity Catalog)"
}

variable "prefix" {
  type        = string
  description = "Prefix for resources (auto-computed from product_name if not provided)"
  default     = null
}

########################################
# Secrets Manager Configuration
########################################

variable "workspace_pat" {
  type        = string
  sensitive   = true
  description = "Databricks Personal Access Token. Leave empty for Pass-1, add PAT here for Pass-2. Terraform automatically stores it in Secrets Manager."
  default     = null
}

variable "use_secrets_manager" {
  type        = bool
  description = "Whether to use AWS Secrets Manager for storing/retrieving workspace credentials"
  default     = true
}

variable "workspace_pat_override" {
  type        = string
  sensitive   = true
  description = "Override workspace PAT (takes precedence over Secrets Manager)"
  default     = null
}

variable "workspace_url_override" {
  type        = string
  description = "Override workspace URL (takes precedence over Secrets Manager)"
  default     = null
}

########################################
# Shared Metastore Configuration
########################################

variable "shared_metastore_id" {
  type        = string
  description = "ID of existing Unity Catalog metastore to assign to workspace. If provided, metastore will not be created, only assigned."
}

variable "create_metastore" {
  type        = bool
  description = "Whether to create a new metastore (true) or use existing shared_metastore_id (false). Default: false (use shared metastore)."
  default     = false
}

