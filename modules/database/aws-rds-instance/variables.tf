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
  description = "VPC in which to create the instance's security group."
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
  description = "Security groups allowed to connect to the instance on the DB port."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the instance on the DB port."
  type        = list(string)
  default     = []
}

variable "publicly_accessible" {
  description = "Assign a public IP and make the instance reachable from outside the VPC."
  type        = bool
  default     = false
}

###############################################################################
# Engine
###############################################################################
variable "engine" {
  description = "Database engine (e.g. postgres, mysql, mariadb)."
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version. Leave null to use the region's current default for the engine."
  type        = string
  default     = null
}

variable "port" {
  description = "Port the database listens on (5432 for PostgreSQL, 3306 for MySQL)."
  type        = number
  default     = 5432
}

variable "database_name" {
  description = "Name of the initial database created on the instance."
  type        = string
}

###############################################################################
# Compute / storage
###############################################################################
variable "instance_class" {
  description = "Instance class for the DB instance."
  type        = string
  default     = "db.t4g.medium"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper limit in GiB for storage autoscaling. Set 0 to disable autoscaling."
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1, io2). Null lets AWS choose the engine default."
  type        = string
  default     = "gp3"
}

variable "iops" {
  description = "Provisioned IOPS. Only valid for io1/io2 and some gp3 configurations; null otherwise."
  type        = number
  default     = null
}

variable "storage_encrypted" {
  description = "Encrypt instance storage at rest."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for storage encryption. Null uses the default aws/rds key."
  type        = string
  default     = null
}

variable "multi_az" {
  description = "Deploy a standby in a second AZ for high availability."
  type        = bool
  default     = false
}

###############################################################################
# Credentials
###############################################################################
variable "master_username" {
  description = "Master username for the instance."
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
# Backup / maintenance / monitoring
###############################################################################
variable "backup_retention_period" {
  description = "Days to retain automated backups (0-35; 0 disables backups)."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 0 and 35."
  }
}

variable "backup_window" {
  description = "Daily UTC time range for automated backups, e.g. 03:00-04:00. Null lets AWS choose."
  type        = string
  default     = null
}

variable "maintenance_window" {
  description = "Weekly UTC maintenance window, e.g. Mon:04:00-Mon:05:00. Null lets AWS choose."
  type        = string
  default     = null
}

variable "copy_tags_to_snapshot" {
  description = "Copy instance tags to snapshots."
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Seconds between Enhanced Monitoring metric collection (0 disables; 1, 5, 10, 15, 30, 60)."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be one of 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights on the instance."
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Days to retain Performance Insights data (7, or a multiple of 31 up to 731)."
  type        = number
  default     = 7
}

variable "ca_cert_identifier" {
  description = "Certificate authority identifier for the instance. Null uses the account default."
  type        = string
  default     = null
}

###############################################################################
# Lifecycle / protection
###############################################################################
variable "deletion_protection" {
  description = "Prevent the instance from being deleted. Recommended true for production."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy. Set false (take a snapshot) for production."
  type        = bool
  default     = false
}

variable "allow_major_version_upgrade" {
  description = "Allow major engine version upgrades, which may be irreversible."
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
