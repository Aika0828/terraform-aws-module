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

###############################################################################
# Networking
###############################################################################
variable "vpc_id" {
  description = "VPC in which to create the replication group's security group."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ElastiCache subnet group."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "Provide at least one subnet ID."
  }
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to Redis on the cache port."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to Redis on the cache port."
  type        = list(string)
  default     = []
}

variable "port" {
  description = "Port Redis listens on."
  type        = number
  default     = 6379
}

###############################################################################
# Engine / sizing
###############################################################################
variable "engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "node_type" {
  description = "Node instance type for each cache node."
  type        = string
  default     = "cache.t4g.small"
}

variable "num_cache_clusters" {
  description = "Number of nodes (primary + replicas). Greater than 1 enables automatic failover and Multi-AZ."
  type        = number
  default     = 1

  validation {
    condition     = var.num_cache_clusters >= 1
    error_message = "num_cache_clusters must be at least 1."
  }
}

variable "parameter_group_name" {
  description = "Cache parameter group name. Null uses the engine's default parameter group."
  type        = string
  default     = null
}

###############################################################################
# Security
###############################################################################
variable "at_rest_encryption_enabled" {
  description = "Encrypt data at rest."
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Encrypt data in transit (TLS)."
  type        = bool
  default     = true
}

variable "auth_token" {
  description = "AUTH token (password) for Redis. Requires transit encryption. Null disables AUTH."
  type        = string
  default     = null
  sensitive   = true
}

variable "snapshot_retention_limit" {
  description = "Days to retain automatic snapshots (0 disables snapshots)."
  type        = number
  default     = 0
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
