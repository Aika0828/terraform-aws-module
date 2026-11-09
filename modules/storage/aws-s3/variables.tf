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
# Bucket
###############################################################################
variable "bucket_name" {
  description = "Explicit bucket name. Null derives it from project_name, a suffix and environment."
  type        = string
  default     = null
}

variable "bucket_suffix" {
  description = "Suffix used when bucket_name is null (e.g. 'assets' -> <project>-assets-<env>)."
  type        = string
  default     = "bucket"
}

variable "force_destroy" {
  description = "Allow deleting a non-empty bucket on destroy. Keep false for anything important."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable object versioning on the bucket."
  type        = bool
  default     = true
}

###############################################################################
# Encryption (SSE)
###############################################################################
variable "encryption" {
  description = "Server-side encryption. Use aws:kms with kms_key_id for a CMK, or AES256 for SSE-S3."
  type = object({
    sse_algorithm      = optional(string, "AES256") # AES256 or aws:kms
    kms_key_id         = optional(string)
    bucket_key_enabled = optional(bool, true)
  })
  default = {}

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption.sse_algorithm)
    error_message = "encryption.sse_algorithm must be AES256 or aws:kms."
  }
}

###############################################################################
# Public access block (all blocked by default)
###############################################################################
variable "block_public_access" {
  description = "Public access block settings. All true by default."
  type = object({
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  })
  default = {}
}

###############################################################################
# Lifecycle rules (optional)
###############################################################################
variable "lifecycle_rules" {
  description = "Optional lifecycle rules for expiration and storage-class transitions."
  type = list(object({
    id                                     = string
    enabled                                = optional(bool, true)
    prefix                                 = optional(string)
    expiration_days                        = optional(number)
    noncurrent_version_expiration_days     = optional(number)
    abort_incomplete_multipart_upload_days = optional(number)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
  }))
  default = []
}

###############################################################################
# Bucket policy (optional) — rendered JSON passed in as a string. No IAM here.
###############################################################################
variable "bucket_policy" {
  description = "Optional bucket policy document as a JSON string. Null leaves no policy."
  type        = string
  default     = null
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto the bucket, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
