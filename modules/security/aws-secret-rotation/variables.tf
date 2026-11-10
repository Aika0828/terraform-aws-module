variable "project_name" {
  description = "Project identifier, used as the first part of every resource name."
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
  description = "Override the rotation function name. Null uses <project>-<environment>-secret-rotation."
  type        = string
  default     = null
}

###############################################################################
# Rotation Lambda (NO IAM — the role is supplied)
###############################################################################
variable "role_arn" {
  description = "IAM role ARN the rotation Lambda assumes. This module creates no IAM."
  type        = string
}

variable "runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "handler" {
  description = "Lambda handler."
  type        = string
  default     = "lambda_function.lambda_handler"
}

# Package source — supply exactly one of these.
variable "source_dir" {
  description = "Directory to zip into the deployment package."
  type        = string
  default     = null
}

variable "source_file" {
  description = "Single file to zip into the deployment package."
  type        = string
  default     = null
}

variable "filename" {
  description = "Path to a pre-built .zip deployment package."
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket holding the deployment package (use with s3_key)."
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of the deployment package (use with s3_bucket)."
  type        = string
  default     = null
}

variable "memory_size" {
  description = "Lambda memory (MiB)."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Lambda timeout (seconds)."
  type        = number
  default     = 30
}

variable "environment_variables" {
  description = "Environment variables for the rotation Lambda."
  type        = map(string)
  default     = {}
}

variable "vpc_subnet_ids" {
  description = "Subnets for the Lambda (empty = not VPC-attached)."
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "Security groups for the Lambda when VPC-attached."
  type        = list(string)
  default     = []
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention for the Lambda."
  type        = number
  default     = 14
}

###############################################################################
# Rotation
###############################################################################
variable "secret_arns" {
  description = "Secrets Manager secret ARNs to attach rotation to."
  type        = list(string)
}

variable "rotation_automatically_after_days" {
  description = "Rotate each secret automatically after this many days."
  type        = number
  default     = 30
}

variable "rotation_duration" {
  description = "Length of the rotation window, e.g. \"3h\". Null lets AWS choose."
  type        = string
  default     = null
}

variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
