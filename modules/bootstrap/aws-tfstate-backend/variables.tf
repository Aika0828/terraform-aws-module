###############################################################################
# Identity
###############################################################################
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

###############################################################################
# S3 state bucket
###############################################################################
variable "bucket_name" {
  description = "Name of the S3 bucket that holds Terraform state. Null derives '<project>-<env>-tfstate'. Bucket names are globally unique."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for S3 state encryption. Null uses SSE-S3 (AES256)."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Allow the state bucket to be destroyed even when it still holds objects. Keep false for real backends."
  type        = bool
  default     = false
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which noncurrent (old) state versions are expired."
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days >= 1
    error_message = "noncurrent_version_expiration_days must be at least 1."
  }
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
