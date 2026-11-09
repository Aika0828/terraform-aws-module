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
# Dashboard (optional)
###############################################################################
variable "dashboard_name" {
  description = "Name for the CloudWatch dashboard. Null derives it from project_name and environment."
  type        = string
  default     = null
}

variable "dashboard_body" {
  description = "Dashboard definition as a JSON string (e.g. from templatefile or jsonencode). Null skips creating a dashboard."
  type        = string
  default     = null
}

###############################################################################
# Metric alarms (optional)
###############################################################################
variable "alarms" {
  description = "Metric alarms to create. alarm_actions / ok_actions take SNS topic (or other) ARNs — this module creates no IAM or SNS resources."
  type = list(object({
    alarm_name          = string
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    threshold           = number
    statistic           = optional(string, "Average")
    alarm_description   = optional(string)
    dimensions          = optional(map(string), {})
    treat_missing_data  = optional(string, "missing")
    datapoints_to_alarm = optional(number)
    alarm_actions       = optional(list(string), [])
    ok_actions          = optional(list(string), [])
  }))
  default = []
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto each alarm, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
