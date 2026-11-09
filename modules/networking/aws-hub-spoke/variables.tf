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
# VPC / subnets
###############################################################################
variable "vpc_cidr" {
  description = "CIDR block for the spoke VPC."
  type        = string
}

variable "availability_zones" {
  description = <<-EOT
    Per-AZ subnet layout. Each entry names an availability zone and gives the
    CIDRs for each subnet tier in that AZ. Any tier list may be empty.
  EOT
  type = list(object({
    name                         = string
    application_subnet_cidrs     = optional(list(string), [])
    database_subnet_cidrs        = optional(list(string), [])
    transit_gateway_subnet_cidrs = optional(list(string), [])
    vpc_endpoint_subnet_cidrs    = optional(list(string), [])
  }))

  validation {
    condition     = length(var.availability_zones) > 0
    error_message = "Provide at least one availability zone."
  }
}

###############################################################################
# Transit gateway
###############################################################################
variable "transit_gateway_id" {
  description = <<-EOT
    ID of the (already shared) transit gateway to attach this VPC to. When empty,
    no attachment is created and no default route to the TGW is added. Acceptance
    and the hub/network-account routing are handled outside this module.
  EOT
  type        = string
  default     = ""
}

variable "transit_gateway_default_route" {
  description = "Add a 0.0.0.0/0 route to the transit gateway on the application, database and VPC-endpoint route tables."
  type        = bool
  default     = true
}

###############################################################################
# VPC endpoints
###############################################################################
variable "interface_endpoint_services" {
  description = <<-EOT
    Short service names for interface VPC endpoints, created in the VPC-endpoint
    subnets (e.g. "ecr.api", "ssm"). Expanded to com.amazonaws.<region>.<name>.
    Set to [] to create no interface endpoints.
  EOT
  type        = list(string)
  default     = ["ecr.api", "ecr.dkr", "ssm", "secretsmanager", "xray", "kinesis-streams"]
}

variable "gateway_endpoint_services" {
  description = "Short service names for gateway VPC endpoints (e.g. \"s3\", \"dynamodb\"), associated with all workload route tables."
  type        = list(string)
  default     = ["s3"]
}

###############################################################################
# Flow logs
###############################################################################
variable "enable_flow_logs" {
  description = "Create a CloudWatch Logs flow log that captures all traffic for the VPC."
  type        = bool
  default     = false
}

variable "flow_log_role_arn" {
  description = "ARN of an existing IAM role the VPC Flow Logs service assumes to deliver records to CloudWatch Logs. Required when enable_flow_logs = true (this module creates no IAM)."
  type        = string
  default     = null
}

variable "flow_log_retention_days" {
  description = "Retention, in days, for the flow-log CloudWatch Logs group."
  type        = number
  default     = 365
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
