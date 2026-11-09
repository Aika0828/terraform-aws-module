###############################################################################
# Identity
###############################################################################
variable "project_name" {
  description = "Project / application identifier, used as the first part of every resource name."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, uat, prod). Used in resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.environment))
    error_message = "environment must be lowercase alphanumeric (e.g. dev, uat, prod)."
  }
}

###############################################################################
# IAM (NO IAM is created here — pass in the Lambda execution role)
###############################################################################
variable "lambda_role_arn" {
  description = "ARN of the IAM role the Lambda assumes. The role is created outside this module and must allow rds snapshot describe/create/delete/tag and CloudWatch Logs."
  type        = string
}

###############################################################################
# Target database
###############################################################################
variable "db_instance_identifier" {
  description = "Identifier of the RDS instance to snapshot."
  type        = string
}

###############################################################################
# Schedule / retention
###############################################################################
variable "retention_days" {
  description = "Days to retain managed manual snapshots before cleanup expires them. The most recent snapshot is always kept."
  type        = number
  default     = 7

  validation {
    condition     = var.retention_days >= 1
    error_message = "retention_days must be at least 1."
  }
}

variable "create_schedule_cron" {
  description = "EventBridge cron expression (without the surrounding cron()) for taking the daily snapshot, e.g. 0 18 * * ? *."
  type        = string
  default     = "0 18 * * ? *"
}

variable "cleanup_schedule_cron" {
  description = "EventBridge cron expression (without the surrounding cron()) for expiring old snapshots, e.g. 30 18 * * ? *."
  type        = string
  default     = "30 18 * * ? *"
}

variable "snapshot_prefix" {
  description = "Prefix for snapshot identifiers. Leave null to derive it from project_name and environment."
  type        = string
  default     = null
}

variable "lambda_runtime" {
  description = "Python runtime for the Lambda function."
  type        = string
  default     = "python3.13"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds."
  type        = number
  default     = 120
}

variable "log_retention_days" {
  description = "Retention of the Lambda's CloudWatch log group, in days."
  type        = number
  default     = 365
}

###############################################################################
# Alerting (optional)
###############################################################################
variable "create_sns_topic" {
  description = "Create an SNS topic and a CloudWatch alarm that fires on Lambda failures."
  type        = bool
  default     = true
}

variable "alert_recipient_emails" {
  description = "Email addresses subscribed to the failure-alert SNS topic (only used when create_sns_topic = true)."
  type        = list(string)
  default     = []
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
