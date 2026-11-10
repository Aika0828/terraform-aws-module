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
# Service roles (created by the caller — this module creates no IAM)
###############################################################################
variable "codepipeline_role_arn" {
  description = "ARN of the IAM service role assumed by CodePipeline. Created by the caller."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/", var.codepipeline_role_arn))
    error_message = "codepipeline_role_arn must be a valid IAM role ARN."
  }
}

variable "codebuild_role_arn" {
  description = "ARN of the IAM service role assumed by the CodeBuild project. Required when codebuild is set. Created by the caller."
  type        = string
  default     = null

  validation {
    condition     = var.codebuild_role_arn == null || can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/", var.codebuild_role_arn))
    error_message = "codebuild_role_arn must be a valid IAM role ARN."
  }
}

###############################################################################
# Artifact bucket (provide an existing one, or let the module create it)
###############################################################################
variable "artifact_bucket_name" {
  description = "Name of an existing S3 bucket for pipeline artifacts. Null makes the module create one."
  type        = string
  default     = null
}

variable "artifact_kms_key_arn" {
  description = "KMS key ARN for the created artifact bucket's encryption. Null uses SSE-S3 (AES256). Ignored when artifact_bucket_name is set."
  type        = string
  default     = null
}

variable "artifact_expiration_days" {
  description = "Days after which current artifacts in the created bucket are expired."
  type        = number
  default     = 30
}

variable "artifact_noncurrent_expiration_days" {
  description = "Days after which noncurrent artifact versions in the created bucket are expired."
  type        = number
  default     = 7
}

variable "artifact_bucket_force_destroy" {
  description = "Allow the created artifact bucket to be destroyed even when it still holds objects."
  type        = bool
  default     = true
}

###############################################################################
# GitHub source connection (optional — provide an ARN, or create one)
###############################################################################
variable "create_github_connection" {
  description = "Create a CodeStar GitHub connection. It is created PENDING and must be completed in the console before first use."
  type        = bool
  default     = false
}

variable "github_connection_arn" {
  description = "ARN of an existing CodeStar connection to use for source actions. Used when create_github_connection is false."
  type        = string
  default     = null
}

###############################################################################
# CodeBuild project (optional)
###############################################################################
variable "codebuild" {
  description = "Optional CodeBuild project. Null creates none. Its name is auto-injected into any CodeBuild stage action that omits ProjectName."
  type = object({
    compute_type                = optional(string, "BUILD_GENERAL1_SMALL")
    image                       = optional(string, "aws/codebuild/amazonlinux2-x86_64-standard:5.0")
    type                        = optional(string, "LINUX_CONTAINER")
    image_pull_credentials_type = optional(string, "CODEBUILD")
    privileged_mode             = optional(bool, false)
    buildspec                   = optional(string)
    source_type                 = optional(string, "CODEPIPELINE")
    log_retention_days          = optional(number, 30)
    environment_variables = optional(map(object({
      value = string
      type  = optional(string, "PLAINTEXT")
    })), {})
  })
  default = null

  validation {
    condition     = var.codebuild == null ? true : contains(["BUILD_GENERAL1_SMALL", "BUILD_GENERAL1_MEDIUM", "BUILD_GENERAL1_LARGE", "BUILD_GENERAL1_2XLARGE"], var.codebuild.compute_type)
    error_message = "codebuild.compute_type must be a valid CodeBuild compute type."
  }

  validation {
    condition     = var.codebuild == null ? true : (var.codebuild.log_retention_days >= 1 && var.codebuild.log_retention_days <= 3653)
    error_message = "codebuild.log_retention_days must be between 1 and 3653."
  }
}

###############################################################################
# Pipeline
###############################################################################
variable "pipeline_type" {
  description = "Pipeline API type."
  type        = string
  default     = "V2"

  validation {
    condition     = contains(["V1", "V2"], var.pipeline_type)
    error_message = "pipeline_type must be V1 or V2."
  }
}

variable "execution_mode" {
  description = "Pipeline execution mode. QUEUED and PARALLEL require V2."
  type        = string
  default     = "SUPERSEDED"

  validation {
    condition     = contains(["SUPERSEDED", "QUEUED", "PARALLEL"], var.execution_mode) && (var.execution_mode == "SUPERSEDED" || var.pipeline_type == "V2")
    error_message = "execution_mode must be SUPERSEDED, or QUEUED/PARALLEL with V2."
  }
}

variable "push_trigger" {
  description = "Optional V2 connection push filter; branch and file filters are ANDed. source_action_name must match a CodeStarSourceConnection action in stages."
  type = object({
    source_action_name = string
    branches           = list(string)
    file_paths         = optional(list(string), [])
  })
  default = null

  validation {
    condition     = var.push_trigger == null ? true : var.pipeline_type == "V2" && length(var.push_trigger.branches) > 0
    error_message = "push_trigger requires V2 and at least one branch filter."
  }
}

variable "stages" {
  description = "Pipeline stages and their actions. CodeStarSourceConnection actions get ConnectionArn auto-injected; CodeBuild actions get ProjectName auto-injected (when codebuild is set) unless overridden in configuration."
  type = list(object({
    name = string
    actions = list(object({
      name             = string
      category         = string
      owner            = string
      provider         = string
      version          = string
      configuration    = optional(map(string))
      input_artifacts  = optional(list(string))
      output_artifacts = optional(list(string))
      namespace        = optional(string)
      region           = optional(string)
      run_order        = optional(number)
      role_arn         = optional(string)
    }))
  }))

  validation {
    condition     = length(var.stages) >= 2
    error_message = "A pipeline needs at least two stages (a source stage and at least one more)."
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
