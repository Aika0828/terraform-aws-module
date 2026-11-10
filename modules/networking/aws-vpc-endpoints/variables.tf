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
# Target VPC
###############################################################################
variable "vpc_id" {
  description = "VPC in which to create the endpoints (and, when enabled, the shared endpoint security group)."
  type        = string
}

###############################################################################
# Managed security group (for interface endpoints)
###############################################################################
variable "create_security_group" {
  description = "Create a shared security group for interface endpoints. The group is attached to any interface endpoint that does not specify its own security_group_ids."
  type        = bool
  default     = true
}

variable "security_group_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the managed security group on port 443. Ignored when create_security_group = false."
  type        = list(string)
  default     = []
}

###############################################################################
# Interface endpoints
###############################################################################
variable "interface_endpoints" {
  description = <<-EOT
    Interface VPC endpoints to create, keyed by a short name. service_name is the
    full AWS service name (e.g. "com.amazonaws.ap-southeast-1.ecr.api").
    subnet_ids and security_group_ids fall back to default_subnet_ids and the
    managed security group respectively when omitted.
  EOT
  type = map(object({
    service_name        = string
    subnet_ids          = optional(list(string))
    security_group_ids  = optional(list(string))
    private_dns_enabled = optional(bool, true)
  }))
  default = {}
}

variable "default_subnet_ids" {
  description = "Subnet IDs used for any interface endpoint that does not set its own subnet_ids."
  type        = list(string)
  default     = []
}

###############################################################################
# Gateway endpoints
###############################################################################
variable "gateway_endpoints" {
  description = <<-EOT
    Gateway VPC endpoints to create (e.g. S3, DynamoDB), keyed by a short name.
    service_name is the full AWS service name; route_table_ids lists the route
    tables to associate.
  EOT
  type = map(object({
    service_name    = string
    route_table_ids = optional(list(string), [])
  }))
  default = {}
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
