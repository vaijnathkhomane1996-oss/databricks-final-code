#################################
# Required inputs
#################################

variable "databricks_account_id" {
  type        = string
  description = "Databricks Account (MWS) ID. (Kept for interface consistency; not directly used by resources in this module.)"
  sensitive   = true
}

variable "workspace_id" {
  type        = string
  description = "Workspace ID to assign the metastore to."
}

variable "metastore_name" {
  type        = string
  description = "Unity Catalog metastore name."
  validation {
    condition     = length(trim(var.metastore_name)) > 0
    error_message = "metastore_name cannot be empty."
  }
}

variable "metastore_region" {
  type        = string
  description = "AWS region for the UC metastore (e.g. us-east-2)."
  validation {
    condition     = can(regex("^([a-z]{2}-[a-z]+-\\d)$", var.metastore_region))
    error_message = "metastore_region must look like an AWS region, e.g. us-east-2."
  }
}
#################################
# Mandatory tags
#################################
# We enforce presence of keys: owner, project, env
variable "tags" {
  description = "A map of tags to assign to all resources. Required tags: owner, env, product, service, repo, created_by, customer, region."
  type        = map(string)
  default     = {
    created_by = "terraform"
  }

  validation {
    condition     = contains(keys(var.tags), "owner")
    error_message = "The 'owner' tag is mandatory and must be provided in the tags variable."
  }

  validation {
    condition     = contains(keys(var.tags), "env")
    error_message = "The 'env' tag is mandatory and must be provided in the tags variable."
  }

  validation {
    condition     = contains(["intg", "stag", "prod", "demo"], var.tags["env"])
    error_message = "The 'env' tag value must be one of: intg, stag, prod, demo."
  }

  validation {
    condition     = contains(keys(var.tags), "product")
    error_message = "The 'product' tag is mandatory and must be provided in the tags variable."
  }

  validation {
    condition     = contains(keys(var.tags), "service")
    error_message = "The 'service' tag is mandatory and must be provided in the tags variable."
  }

  validation {
    condition     = contains(keys(var.tags), "repo")
    error_message = "The 'repo' tag is mandatory and must be provided in the tags variable."
  }

  validation {
    condition     = contains(keys(var.tags), "created_by")
    error_message = "The 'created_by' tag is mandatory and must be provided in the tags variable."
  }

  validation {
    condition     = contains(keys(var.tags), "customer")
    error_message = "The 'customer' tag is mandatory and must be provided in the tags variable."
  }

  validation {
    condition     = contains(keys(var.tags), "region")
    error_message = "The 'region' tag is mandatory and must be provided in the tags variable."
  }

  validation {
    condition     = alltrue([for k, v in var.tags : can(regex("^[a-zA-Z0-9_\\-:]+$", k))])
    error_message = "Tag keys must contain only letters, numbers, underscores, hyphens, and colons."
  }

  validation {
    condition     = alltrue([for k, v in var.tags : length(k) >= 1 && length(k) <= 128])
    error_message = "Tag keys must be between 1 and 128 characters long."
  }

  validation {
    condition     = alltrue([for k, v in var.tags : length(v) >= 0 && length(v) <= 256])
    error_message = "Tag values must be between 0 and 256 characters long."
  }

  validation {
    condition     = alltrue([for k, v in var.tags : k != "aws:" && k != "Name"])
    error_message = "Tag keys cannot start with 'aws:' or be 'Name' as these are reserved."
  }
}

variable "unity_metastore_owner" {
  type      = string
  sensitive = true
}
variable "prefix" {
  type = string
}

variable "aws_account_id" {
  type      = string
  sensitive = true
}

########################################
# Unity Catalog Storage Configuration
########################################

variable "uc_external_bucket" {
  type        = string
  description = "S3 bucket name for Unity Catalog external location."
  default     = null
}

variable "uc_external_prefix" {
  type        = string
  description = "S3 prefix/folder within the external bucket for Unity Catalog."
  default     = ""
}

variable "uc_storage_role_arn" {
  type        = string
  description = "IAM role ARN used for Unity Catalog storage credentials."
  default     = null
}