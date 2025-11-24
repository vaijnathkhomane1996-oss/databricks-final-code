variable "project" {
  description = "Project/product name."
  type        = string
}

variable "env" {
  description = "Environment (e.g., integration|staging|prod)."
  type        = string
}

variable "region" {
  description = "AWS region where the workspace is deployed."
  type        = string
}

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
    condition     = contains(["intg", "stag", "prod"], var.tags["env"])
    error_message = "The 'env' tag value must be one of: intg, stag, prod."
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

# Optional workspace preferences
variable "workspace_name" {
  description = "Explicit workspace name (defaults to <project>-<env>-workspace)."
  type        = string
  default     = null
}

variable "prefix" { 
  type = string 
  }

  variable "root_storage_bucket" {
  type        = string
  description = "Name of the S3 bucket used as the root storage bucket."
}

variable "cross_account_role_arn" {
  type        = string
  description = "IAM role ARN used for cross-account access."
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to attach."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC to deploy into."
}

variable "vpc_private_subnets" {
  type        = list(string)
  description = "List of private subnet IDs in the VPC."
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID."
}

variable "product_name" {
  description = "Name of the product"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "Region where resources will be deployed"
  type        = string
}

########################################
# Databricks MWS Configuration
########################################

variable "credentials_id" {
  type        = string
  description = "MWS credentials ID (cross-account role)."
  default     = null
}

variable "storage_configuration_id" {
  type        = string
  description = "MWS storage configuration ID."
  default     = null
}

variable "network_id" {
  type        = string
  description = "MWS network ID (workspace VPC attachment)."
  default     = null
}

variable "private_access_settings_id" {
  type        = string
  description = "MWS private access settings ID."
  default     = null
}

########################################
# Workspace Configuration
########################################

variable "deployment_name" {
  description = "Optional deployment name suffix."
  type        = string
  default     = null
}

variable "pricing_tier" {
  description = "Databricks pricing tier (standard, premium, enterprise)."
  type        = string
  default     = "premium"
  validation {
    condition     = contains(["standard", "premium", "enterprise"], lower(var.pricing_tier))
    error_message = "pricing_tier must be one of: standard, premium, enterprise."
  }
}