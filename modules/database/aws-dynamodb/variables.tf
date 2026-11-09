###############################################################################
# Identity
###############################################################################
variable "project_name" {
  description = "Project / application identifier, used as the first part of the table name."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, uat, prod). Used in the table name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.environment))
    error_message = "environment must be lowercase alphanumeric (e.g. dev, uat, prod)."
  }
}

###############################################################################
# Table
###############################################################################
variable "table_name" {
  description = "Table suffix. The full table name is \"<project_name>-<environment>-<table_name>\"."
  type        = string
}

variable "billing_mode" {
  description = "Billing mode: PAY_PER_REQUEST (on-demand) or PROVISIONED."
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "billing_mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "read_capacity" {
  description = "Provisioned read capacity units. Required (and only used) when billing_mode = PROVISIONED."
  type        = number
  default     = null
}

variable "write_capacity" {
  description = "Provisioned write capacity units. Required (and only used) when billing_mode = PROVISIONED."
  type        = number
  default     = null
}

variable "hash_key" {
  description = "Name of the attribute used as the partition (hash) key."
  type        = string
}

variable "range_key" {
  description = "Name of the attribute used as the sort (range) key. Null for no sort key."
  type        = string
  default     = null
}

variable "attributes" {
  description = "Attribute definitions referenced by the keys and indexes. Each type is S (string), N (number), or B (binary)."
  type = list(object({
    name = string
    type = string
  }))

  validation {
    condition     = alltrue([for a in var.attributes : contains(["S", "N", "B"], a.type)])
    error_message = "Each attribute type must be S, N, or B."
  }
}

variable "global_secondary_indexes" {
  description = "Global secondary indexes. read_capacity/write_capacity apply only under PROVISIONED billing; non_key_attributes only with projection_type = INCLUDE."
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string)
    projection_type    = optional(string, "ALL")
    non_key_attributes = optional(list(string))
    read_capacity      = optional(number)
    write_capacity     = optional(number)
  }))
  default = []
}

variable "ttl" {
  description = "Time-to-live configuration. Null disables TTL."
  type = object({
    attribute_name = string
    enabled        = optional(bool, true)
  })
  default = null
}

variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery (continuous backups)."
  type        = bool
  default     = true
}

variable "server_side_encryption" {
  description = "Server-side encryption. enabled = false uses the AWS-owned key; a kms_key_arn selects a customer-managed CMK (otherwise the AWS-managed aws/dynamodb key)."
  type = object({
    enabled     = optional(bool, true)
    kms_key_arn = optional(string)
  })
  default = {}
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto the table, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
