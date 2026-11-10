###############################################################################
# Identity
###############################################################################
variable "project_name" {
  description = "Project identifier, used as the first part of every resource name."
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

variable "function_name" {
  description = "Logical function name, appended to <project>-<environment>- to form the full Lambda name."
  type        = string
}

###############################################################################
# Execution role (created elsewhere — this module never creates IAM)
###############################################################################
variable "role_arn" {
  description = "ARN of the IAM execution role the function assumes. Created outside this module."
  type        = string
}

###############################################################################
# Runtime
###############################################################################
variable "runtime" {
  description = "Lambda runtime identifier, e.g. python3.13, nodejs20.x."
  type        = string
}

variable "handler" {
  description = "Function entrypoint, e.g. index.handler."
  type        = string
}

variable "memory_size" {
  description = "Memory allocated to the function, in MB."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Function timeout, in seconds."
  type        = number
  default     = 30
}

variable "architectures" {
  description = "Instruction set architecture for the function."
  type        = list(string)
  default     = ["x86_64"]
}

variable "environment_variables" {
  description = "Environment variables passed to the function."
  type        = map(string)
  default     = {}
}

variable "layers" {
  description = "List of Lambda layer version ARNs to attach."
  type        = list(string)
  default     = []
}

###############################################################################
# Deployment package — provide exactly one source:
#   - source_dir  : a directory zipped at plan time, OR
#   - source_file : a single file zipped at plan time, OR
#   - filename    : a path to a pre-built .zip, OR
#   - s3_bucket + s3_key : an object already in S3
###############################################################################
variable "source_dir" {
  description = "Directory zipped into the deployment package. Mutually exclusive with source_file, filename, and the S3 inputs."
  type        = string
  default     = null
}

variable "source_file" {
  description = "Single file zipped into the deployment package. Mutually exclusive with source_dir, filename, and the S3 inputs."
  type        = string
  default     = null
}

variable "filename" {
  description = "Path to a pre-built .zip deployment package. Mutually exclusive with source_dir, source_file, and the S3 inputs."
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket holding the deployment package. Requires s3_key."
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of the deployment package. Requires s3_bucket."
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "Version ID of the S3 deployment-package object."
  type        = string
  default     = null
}

###############################################################################
# VPC (optional)
###############################################################################
variable "vpc_config" {
  description = "Attach the function to a VPC. Null runs the function outside any VPC."
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

###############################################################################
# Logging
###############################################################################
variable "log_retention_days" {
  description = "Retention for the function's CloudWatch log group, in days."
  type        = number
  default     = 90
}

variable "log_kms_key_id" {
  description = "KMS key ARN to encrypt the log group. Null uses the default CloudWatch Logs encryption."
  type        = string
  default     = null
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
