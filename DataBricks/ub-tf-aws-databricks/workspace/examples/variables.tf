variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "databricks_account_id" {
  type = string
}

variable "databricks_username" {
  type = string
}

variable "databricks_password" {
  type = string
}

variable "private_access_settings_id" {
  type = string
}

variable "credentials_id" {
  type = string
}

variable "storage_configuration_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "pricing_tier" {
  type    = string
  default = "premium"
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


variable "databricks_secret_name" {
  description = "Name or ARN of the secret that contains the Databricks credentials"
  type        = string
   }