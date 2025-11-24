#############################################
# Core identity
#############################################

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

variable "region" {
  description = "AWS region"
  type        = string
}

#############################################
# Existing VPC
#############################################

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

#############################################
# Workspace Storage Configuration (Required by Repo A)
#############################################

variable "root_storage_bucket" {
  type        = string
  description = "S3 bucket name used as root storage bucket for Databricks workspace"
}

variable "cross_account_role_arn" {
  type        = string
  description = "IAM role ARN used for cross-account access (required for Databricks workspace)"
}

#############################################
# Databricks Account / MWS IDs
#############################################

variable "databricks_account_id" {
  type = string
}

variable "mws_credentials_id" {
  type = string
}

variable "mws_storage_config_id" {
  type = string
}

variable "mws_network_id" {
  type = string
}

variable "mws_private_access_settings_id" {
  type = string
}

#############################################
# Workspace Authentication (for clusters and UC)
#############################################

variable "workspace_pat" {
  type        = string
  sensitive   = true
  description = "Databricks Personal Access Token for workspace operations (clusters, catalogs). If not provided, will be retrieved from AWS Secrets Manager."
  default     = null
}

variable "workspace_pat_override" {
  type        = string
  sensitive   = true
  description = "Override workspace PAT (takes precedence over Secrets Manager). Leave null to use Secrets Manager."
  default     = null
}

variable "workspace_url_override" {
  type        = string
  description = "Override workspace URL (takes precedence over Secrets Manager/state). Leave null to use Secrets Manager or module output."
  default     = null
}

variable "use_secrets_manager" {
  type        = bool
  description = "Whether to use AWS Secrets Manager for storing/retrieving workspace credentials. Set to false to use variables only."
  default     = true
}

variable "aws_account_id" {
  type        = string
  sensitive   = true
  description = "AWS account ID (required for Unity Catalog)"
  # No default - must be provided
}

variable "unity_metastore_owner" {
  type        = string
  sensitive   = true
  description = "Unity Catalog metastore owner (required for Unity Catalog)"
  # No default - must be provided
}

variable "prefix" {
  type        = string
  description = "Prefix for resources (required for Unity Catalog)"
  # No default - must be provided
}

#############################################
# Shared Metastore Configuration
#############################################

variable "shared_metastore_id" {
  type        = string
  description = "ID of existing Unity Catalog metastore to assign to workspace (for shared metastore across environments). If provided, metastore will not be created, only assigned."
  default     = null
}

variable "create_metastore" {
  type        = bool
  description = "Whether to create a new metastore (true) or use existing shared_metastore_id (false). Default: true (create new)."
  default     = true
}

#############################################
# Workspace + UC + Multiple Clusters
#############################################

variable "workspace" {
  type = object({
    # Workspace
    workspace_name = string
    pricing_tier   = string

    # UC
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
    catalogs = map(object({
      storage_root = string

      grants = optional(list(object({
        principal  = string
        privileges = list(string)
      })), [])
    }))
  })
}

#############################################
# Mandatory corporate tags
#############################################

variable "tags" {
  description = "Required corporate tags"
  type        = map(string)
  default     = {
    created_by = "terraform"
  }

  validation {
    condition     = contains(keys(var.tags), "owner")
    error_message = "'owner' tag is required."
  }

  validation {
    condition     = contains(keys(var.tags), "env")
    error_message = "'env' tag is required."
  }

  validation {
    condition     = contains(["intg", "stag", "prod", "demo"], var.tags["env"])
    error_message = "'env' must be one of intg, stag, prod, demo."
  }

  validation {
    condition     = contains(keys(var.tags), "product")
    error_message = "'product' tag is required."
  }

  validation {
    condition     = contains(keys(var.tags), "service")
    error_message = "'service' tag is required."
  }

  validation {
    condition     = contains(keys(var.tags), "repo")
    error_message = "'repo' tag is required."
  }

  validation {
    condition     = contains(keys(var.tags), "created_by")
    error_message = "'created_by' tag is required."
  }

  validation {
    condition     = contains(keys(var.tags), "customer")
    error_message = "'customer' tag is required."
  }

  validation {
    condition     = contains(keys(var.tags), "region")
    error_message = "'region' tag is required."
  }
}
