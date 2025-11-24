########################################
# Workspace-scoped inputs
########################################

variable "workspace_url" {
  type        = string
  description = "Workspace URL (e.g., https://adb-<id>.<region>.azuredatabricks.net or https://<deployment>.cloud.databricks.com)"
  validation {
    condition     = length(trimspace(var.workspace_url)) > 0
    error_message = "workspace_url cannot be empty."
  }
}

variable "workspace_pat" {
  type        = string
  sensitive   = true
  description = "Workspace Personal Access Token used by the cluster provisioning."
  validation {
    condition     = length(trimspace(var.workspace_pat)) > 0
    error_message = "workspace_pat cannot be empty."
  }
}

variable "project" {
  description = "The name of the project."
  type        = string
}

variable "env" {
  description = "The environment name (e.g., dev, staging, prod)."
  type        = string
}

########################################
# Cluster shape
########################################

variable "cluster_name" {
  type        = string
  description = "Shared cluster name."
  validation {
    condition     = length(trimspace(var.cluster_name)) > 0
    error_message = "cluster_name cannot be empty."
  }
}

########################################
# Cluster Configuration (Optional)
########################################

variable "spark_version" {
  type        = string
  description = "Databricks runtime version (e.g., 13.3.x-scala2.12)."
  default     = null
}

variable "node_type_id" {
  type        = string
  description = "Instance type for Databricks worker nodes (e.g., i3.xlarge)."
  default     = null
}

variable "num_workers" {
  type        = number
  description = "Number of worker nodes in the cluster."
  default     = null
}

########################################
# Tagging
########################################

variable "tags"  {
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

variable "department" {
  description = "Department name for organizational tagging"
  type        = string
}

variable "group_name" {
  description = "Group or team name associated with the cluster"
  type        = string
}

variable "product_name" {
  description = "Name of the product (optional, not used by module but kept for compatibility)"
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod) (optional, not used by module but kept for compatibility)"
  type        = string
  default     = null
}

variable "region" {
  description = "Region where resources will be deployed (optional, not used by module but kept for compatibility)"
  type        = string
  default     = null
}
