variable "project_name" {
  description = "Project / application identifier, used as the first part of the cluster name."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, uat, prod)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.environment))
    error_message = "environment must be lowercase alphanumeric (e.g. dev, uat, prod)."
  }
}

variable "name" {
  description = "Override the cluster name. Null uses <project_name>-<environment>-cluster."
  type        = string
  default     = null
}

variable "container_insights" {
  description = "CloudWatch Container Insights setting: enabled or disabled."
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.container_insights)
    error_message = "container_insights must be 'enabled' or 'disabled'."
  }
}

variable "capacity_providers" {
  description = "Capacity providers available to the cluster."
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider" {
  description = "Capacity provider used by the default strategy."
  type        = string
  default     = "FARGATE"
}

variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
