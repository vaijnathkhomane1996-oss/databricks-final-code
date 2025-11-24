# Naming / env
variable "project" {
  type = string
}

variable "env" {
  type = string
}

# Metastore inputs
variable "metastore_name" {
  type = string
}

variable "metastore_region" {
  type = string
}

# UC S3 location + IAM role
variable "uc_external_bucket" {
  type = string
}

variable "uc_external_prefix" {
  type    = string
  default = ""
}

variable "uc_storage_role_arn" {
  type = string
  sensitive = true
}

# Workspace ID to assign the metastore to
variable "workspace_id" {
  type = string
}

# Workspace provider auth (single-pass)
variable "workspace_url" {
  type = string
  sensitive = true
}

variable "workspace_pat" {
  type      = string
  sensitive = true
}


variable "databricks_secret_name" {
  description = "Name or ARN of the secret that contains the Databricks credentials"
  type        = string
  sensitive = true
}

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