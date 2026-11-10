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
  description = "VPC in which to create the proxy's security group. Required only when create_security_group = true."
  type        = string
  default     = null
}

variable "vpc_subnet_ids" {
  description = "Subnet IDs the proxy places its network interfaces into (at least two, in different AZs)."
  type        = list(string)

  validation {
    condition     = length(var.vpc_subnet_ids) >= 2
    error_message = "Provide at least two subnet IDs in different availability zones."
  }
}

variable "create_security_group" {
  description = "Create a security group for the proxy. When false, supply vpc_security_group_ids instead."
  type        = bool
  default     = true
}

variable "vpc_security_group_ids" {
  description = "Security groups to attach to the proxy. Merged with the created SG when create_security_group = true."
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to the proxy on the DB port (only used when create_security_group = true)."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the proxy on the DB port (only used when create_security_group = true)."
  type        = list(string)
  default     = []
}

variable "port" {
  description = "Port the proxy listens on and connects to the target on (5432 for PostgreSQL, 3306 for MySQL)."
  type        = number
  default     = 5432
}

###############################################################################
# Proxy
###############################################################################
variable "engine_family" {
  description = "Database engine family the proxy speaks: POSTGRESQL, MYSQL, or SQLSERVER."
  type        = string
  default     = "POSTGRESQL"

  validation {
    condition     = contains(["POSTGRESQL", "MYSQL", "SQLSERVER"], var.engine_family)
    error_message = "engine_family must be one of POSTGRESQL, MYSQL, or SQLSERVER."
  }
}

variable "require_tls" {
  description = "Require TLS on connections between clients and the proxy."
  type        = bool
  default     = true
}

variable "debug_logging" {
  description = "Include detailed SQL statements in the proxy's CloudWatch logs. Useful for debugging; disable in production."
  type        = bool
  default     = false
}

variable "idle_client_timeout" {
  description = "Seconds a client connection may stay idle before the proxy closes it."
  type        = number
  default     = 1800
}

###############################################################################
# IAM / Secrets (NO IAM is created here — pass in the role and secrets)
###############################################################################
variable "role_arn" {
  description = "ARN of the IAM role the proxy assumes to read the Secrets Manager secrets. The role is created outside this module."
  type        = string
}

variable "secret_arns" {
  description = "Secrets Manager secret ARNs holding the database credentials the proxy connects with (one auth block per secret)."
  type        = list(string)

  validation {
    condition     = length(var.secret_arns) >= 1
    error_message = "Provide at least one Secrets Manager secret ARN."
  }
}

variable "iam_auth" {
  description = "Whether the proxy requires IAM authentication from clients: DISABLED or REQUIRED."
  type        = string
  default     = "DISABLED"

  validation {
    condition     = contains(["DISABLED", "REQUIRED"], var.iam_auth)
    error_message = "iam_auth must be DISABLED or REQUIRED."
  }
}

###############################################################################
# Target
###############################################################################
variable "db_cluster_identifier" {
  description = "Identifier of the RDS/Aurora cluster to register as the proxy target. Set this OR db_instance_identifier."
  type        = string
  default     = null
}

variable "db_instance_identifier" {
  description = "Identifier of the RDS instance to register as the proxy target. Set this OR db_cluster_identifier."
  type        = string
  default     = null
}

variable "connection_borrow_timeout" {
  description = "Seconds to wait for a connection from the pool before returning a timeout error."
  type        = number
  default     = 120
}

variable "max_connections_percent" {
  description = "Maximum size of the connection pool as a percentage of the target's max_connections."
  type        = number
  default     = 100
}

variable "max_idle_connections_percent" {
  description = "Portion of the connection pool kept idle, as a percentage of the target's max_connections."
  type        = number
  default     = 50
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
