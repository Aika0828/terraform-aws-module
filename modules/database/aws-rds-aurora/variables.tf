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
  description = "VPC in which to create the cluster's security group."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group (at least two, in different AZs)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Provide at least two subnet IDs in different availability zones."
  }
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to the cluster on the DB port."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the cluster on the DB port."
  type        = list(string)
  default     = []
}

###############################################################################
# Engine
###############################################################################
variable "engine" {
  description = "Aurora engine: aurora-postgresql or aurora-mysql."
  type        = string
  default     = "aurora-postgresql"

  validation {
    condition     = contains(["aurora-postgresql", "aurora-mysql"], var.engine)
    error_message = "engine must be aurora-postgresql or aurora-mysql."
  }
}

variable "engine_version" {
  description = "Aurora engine version. Leave null to use the region's current default for the engine."
  type        = string
  default     = null
}

variable "port" {
  description = "Port the database listens on (5432 for PostgreSQL, 3306 for MySQL)."
  type        = number
  default     = 5432
}

variable "database_name" {
  description = "Name of the initial database created in the cluster."
  type        = string
}

###############################################################################
# Instances
###############################################################################
variable "instance_class" {
  description = "Instance class for each cluster instance."
  type        = string
  default     = "db.r6g.large"
}

variable "instance_count" {
  description = "Number of cluster instances: 1 writer plus (instance_count - 1) readers."
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1
    error_message = "instance_count must be at least 1."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights on each instance."
  type        = bool
  default     = true
}

###############################################################################
# Credentials
###############################################################################
variable "master_username" {
  description = "Master username for the cluster."
  type        = string
  default     = "dbadmin"
}

variable "manage_master_user_password" {
  description = "Let RDS create and manage the master password in Secrets Manager. When true, Terraform supplies no password."
  type        = bool
  default     = true
}

variable "master_password_secret_arn" {
  description = "Secrets Manager secret ARN whose JSON holds the master password. Required only when manage_master_user_password = false."
  type        = string
  default     = null
}

variable "master_password_secret_json_key" {
  description = "JSON key inside master_password_secret_arn that holds the password."
  type        = string
  default     = "rds_password"
}

###############################################################################
# Backup / protection
###############################################################################
variable "backup_retention_period" {
  description = "Days to retain automated backups (1-35)."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 1 and 35."
  }
}

variable "preferred_backup_window" {
  description = "Daily UTC time range for automated backups, e.g. 03:00-04:00. Null lets AWS choose."
  type        = string
  default     = null
}

variable "storage_encrypted" {
  description = "Encrypt cluster storage at rest."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for storage encryption. Null uses the default aws/rds key."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Prevent the cluster from being deleted. Recommended true for production."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy. Set false (take a snapshot) for production."
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during the maintenance window."
  type        = bool
  default     = false
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}

variable "auto_minor_version_upgrade" {
  description = "Automatically apply minor engine version upgrades during the maintenance window. Defaults to true."
  type        = bool
  default     = true
}
