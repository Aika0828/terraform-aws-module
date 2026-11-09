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
  description = "VPC in which to create the broker's security group. Required only when create_security_group = true."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for the broker. A single-instance broker uses one; a CLUSTER_MULTI_AZ broker uses two in different AZs."
  type        = list(string)
}

variable "create_security_group" {
  description = "Create a security group for the broker. When false, supply security_group_ids instead."
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "Security groups to attach to the broker. Merged with the created SG when create_security_group = true."
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to the broker (only used when create_security_group = true)."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the broker (only used when create_security_group = true)."
  type        = list(string)
  default     = []
}

###############################################################################
# Broker
###############################################################################
variable "engine_version" {
  description = "RabbitMQ engine version."
  type        = string
  default     = "4.2"
}

variable "host_instance_type" {
  description = "Broker host instance type (e.g. mq.m7g.medium)."
  type        = string
  default     = "mq.m7g.medium"
}

variable "deployment_mode" {
  description = "Broker deployment mode: SINGLE_INSTANCE or CLUSTER_MULTI_AZ."
  type        = string
  default     = "CLUSTER_MULTI_AZ"

  validation {
    condition     = contains(["SINGLE_INSTANCE", "CLUSTER_MULTI_AZ"], var.deployment_mode)
    error_message = "deployment_mode must be SINGLE_INSTANCE or CLUSTER_MULTI_AZ."
  }
}

variable "publicly_accessible" {
  description = "Whether the broker has a public endpoint."
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Allow automatic minor-version upgrades during the maintenance window."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply broker changes immediately instead of during the maintenance window."
  type        = bool
  default     = false
}

###############################################################################
# Admin credentials
###############################################################################
variable "admin_username" {
  description = "Administrative RabbitMQ username."
  type        = string
}

variable "admin_password" {
  description = "Administrative RabbitMQ password (minimum 12 characters). Marked sensitive."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "admin_password must be at least 12 characters."
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
