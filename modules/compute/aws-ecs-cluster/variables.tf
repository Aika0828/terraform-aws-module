variable "project_name" {
  description = "Project identifier, used as the first part of the default cluster name."
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

###############################################################################
# Cluster settings
###############################################################################
variable "container_insights" {
  description = "CloudWatch Container Insights setting: enhanced, enabled or disabled."
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["enhanced", "enabled", "disabled"], var.container_insights)
    error_message = "container_insights must be 'enhanced', 'enabled' or 'disabled'."
  }
}

variable "execute_command_configuration" {
  description = <<-EOT
    Optional ECS Exec configuration for the cluster. Null keeps the AWS default.
    logging is one of NONE, DEFAULT or OVERRIDE; log_configuration is only used
    with OVERRIDE.
  EOT
  type = object({
    kms_key_id = optional(string)
    logging    = optional(string, "DEFAULT")
    log_configuration = optional(object({
      cloud_watch_encryption_enabled = optional(bool)
      cloud_watch_log_group_name     = optional(string)
      s3_bucket_name                 = optional(string)
      s3_bucket_encryption_enabled   = optional(bool)
      s3_key_prefix                  = optional(string)
    }))
  })
  default = null

  validation {
    condition = (
      var.execute_command_configuration == null ||
      contains(["NONE", "DEFAULT", "OVERRIDE"], try(var.execute_command_configuration.logging, "DEFAULT"))
    )
    error_message = "execute_command_configuration.logging must be NONE, DEFAULT or OVERRIDE."
  }
}

variable "service_connect_namespace_arn" {
  description = "Cloud Map namespace ARN used as the cluster's Service Connect default. Null disables it."
  type        = string
  default     = null
}

###############################################################################
# Capacity providers
###############################################################################
variable "capacity_providers" {
  description = "Capacity providers associated with the cluster (e.g. FARGATE, FARGATE_SPOT, or an ASG capacity provider name). Empty list skips the association."
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy for services that don't set their own. Every provider listed must also be in capacity_providers."
  type = list(object({
    capacity_provider = string
    weight            = optional(number, 1)
    base              = optional(number, 0)
  }))
  default = [
    { capacity_provider = "FARGATE", weight = 1, base = 0 }
  ]

  validation {
    condition     = length([for s in var.default_capacity_provider_strategy : s if s.base > 0]) <= 1
    error_message = "Only one provider in default_capacity_provider_strategy may set base > 0."
  }
}

variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
