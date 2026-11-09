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
# Networking
###############################################################################
variable "vpc_id" {
  description = "VPC in which to create the domain's security group."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs to place the domain in (one per availability zone)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "Provide at least one subnet ID."
  }
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to the domain over HTTPS."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the domain over HTTPS."
  type        = list(string)
  default     = []
}

variable "port" {
  description = "Port the domain's HTTPS endpoint listens on."
  type        = number
  default     = 443
}

###############################################################################
# Engine / cluster
###############################################################################
variable "engine_version" {
  description = "OpenSearch or Elasticsearch engine version, e.g. OpenSearch_2.9."
  type        = string
  default     = "OpenSearch_2.9"
}

variable "instance_type" {
  description = "Instance type for the data nodes."
  type        = string
  default     = "t3.medium.search"
}

variable "instance_count" {
  description = "Number of data nodes."
  type        = number
  default     = 3
}

variable "zone_awareness_enabled" {
  description = "Spread data nodes across multiple availability zones."
  type        = bool
  default     = true
}

variable "availability_zone_count" {
  description = "Number of AZs for zone awareness (2 or 3). Ignored when zone_awareness_enabled = false."
  type        = number
  default     = 3

  validation {
    condition     = contains([2, 3], var.availability_zone_count)
    error_message = "availability_zone_count must be 2 or 3."
  }
}

variable "ebs_volume_size" {
  description = "EBS volume size in GiB attached to each data node."
  type        = number
  default     = 20
}

variable "ebs_volume_type" {
  description = "EBS volume type for data nodes (e.g. gp3)."
  type        = string
  default     = "gp3"
}

###############################################################################
# Security
###############################################################################
variable "master_username" {
  description = "Master username for the internal user database (fine-grained access control)."
  type        = string
  default     = "admin"
}

variable "master_password_secret_arn" {
  description = "Secrets Manager secret ARN whose JSON holds the master password."
  type        = string
}

variable "master_password_secret_json_key" {
  description = "JSON key inside master_password_secret_arn that holds the password."
  type        = string
  default     = "opensearch_password"
}

variable "access_policies" {
  description = "Domain access policy as a JSON string. Null applies a default policy allowing es:* scoped to the domain (network access is still restricted by the VPC and security group)."
  type        = string
  default     = null
}

###############################################################################
# Logging
###############################################################################
variable "log_publishing_enabled" {
  description = "Publish slow-search logs to a CloudWatch log group created by this module."
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "Retention for the CloudWatch log group."
  type        = number
  default     = 7
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
