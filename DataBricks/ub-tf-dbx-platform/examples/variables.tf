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
}

variable "environment" {
  description = "Environment (intg, stag, prod, demo)"
  type        = string
}

########################################
# Workspace Authentication
########################################

variable "workspace_pat" {
  description = "Databricks Personal Access Token (optional if using Secrets Manager). If not provided, will be retrieved from AWS Secrets Manager."
  type        = string
  sensitive   = true
  default     = null
}

variable "workspace_pat_override" {
  description = "Override workspace PAT (takes precedence over Secrets Manager). Leave null to use Secrets Manager."
  type        = string
  sensitive   = true
  default     = null
}

variable "workspace_url_override" {
  description = "Override workspace URL (takes precedence over Secrets Manager/state). Leave null to use Secrets Manager or module output."
  type        = string
  default     = null
}

variable "use_secrets_manager" {
  description = "Whether to use AWS Secrets Manager for storing/retrieving workspace credentials. Set to false to use variables only."
  type        = bool
  default     = true
}

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
# Unity Catalog Required Variables
########################################

variable "aws_account_id" {
  description = "AWS account ID (required for Unity Catalog metastore creation)"
  type        = string
  sensitive   = true
}

variable "unity_metastore_owner" {
  description = "Unity Catalog metastore owner (email address or service principal)"
  type        = string
  sensitive   = true
}

variable "prefix" {
  description = "Prefix for Unity Catalog resources (e.g., 'dp', 'prod')"
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
# Corporate tags (validated inside Root module)
########################################

variable "tags" {
  description = "Corporate mandatory tags (owner, env, product, service, repo, created_by, customer, region)"
  type        = map(string)
}

########################################
# Workspace + UC + Multiple Clusters + Multiple Catalogs
########################################

variable "workspace" {
  description = "Workspace + Unity Catalog + clusters + catalogs configuration"

  type = object({
    # Workspace
    workspace_name = string
    pricing_tier   = string

    # Unity Catalog
    uc_metastore_name   = string
    uc_metastore_region = string
    uc_external_prefix  = string
    uc_storage_role_arn = string

    # Clusters
    clusters = map(object({
      cluster_name  = string
      spark_version = string
      node_type_id  = string
      num_workers   = number
    }))

    # Catalogs
    catalogs = map(object({
      storage_root = string

      grants = optional(list(object({
        principal  = string
        privileges = list(string)
      })), [])
    }))
  })
}
