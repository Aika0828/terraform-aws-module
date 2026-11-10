###############################################################################
# Identity
###############################################################################
variable "project_name" {
  description = "Project identifier, used as the first part of the linked account name."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, uat, prod). Used in the linked account name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.environment))
    error_message = "environment must be lowercase alphanumeric (e.g. dev, uat, prod)."
  }
}

###############################################################################
# New Relic account
###############################################################################
variable "newrelic_account_id" {
  description = "New Relic account ID that owns the AWS integration. Null uses the account configured on the newrelic provider."
  type        = string
  default     = null
}

###############################################################################
# AWS integration
###############################################################################
variable "integration_role_arn" {
  description = "ARN of the IAM role New Relic assumes to read AWS metrics. Created and managed by the caller — this module provisions no IAM."
  type        = string
}

variable "link_account_name" {
  description = "Display name for the linked AWS account in New Relic. Null derives it from project_name and environment."
  type        = string
  default     = null
}

variable "metric_collection_mode" {
  description = "How New Relic collects metrics: PUSH (CloudWatch Metric Streams) or PULL (polling)."
  type        = string
  default     = "PUSH"

  validation {
    condition     = contains(["PUSH", "PULL"], var.metric_collection_mode)
    error_message = "metric_collection_mode must be PUSH or PULL."
  }
}
