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
# Service network
###############################################################################
variable "create_service_network" {
  description = "Create a VPC Lattice service network. When false, services are associated with the existing network given by service_network_id."
  type        = bool
  default     = true
}

variable "service_network_auth_type" {
  description = "Auth type for the created service network: AWS_IAM or NONE."
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["AWS_IAM", "NONE"], var.service_network_auth_type)
    error_message = "service_network_auth_type must be AWS_IAM or NONE."
  }
}

variable "service_network_vpc_ids" {
  description = "VPC IDs to associate with the created service network."
  type        = list(string)
  default     = []
}

variable "service_network_id" {
  description = "ID of an existing service network to associate services with. Required when create_service_network = false."
  type        = string
  default     = null
}

###############################################################################
# Targets VPC (for target groups)
###############################################################################
variable "vpc_id" {
  description = "VPC in which the services' target groups register targets. Required when any services are defined."
  type        = string
  default     = null
}

###############################################################################
# Services
###############################################################################
variable "services" {
  description = <<-EOT
    VPC Lattice services to create, keyed by a short name. Each service gets a
    target group, an HTTPS listener forwarding to it, and an association to the
    service network. Set `principals` (with auth_type = AWS_IAM) to attach an
    auth policy allowing those principal ARNs to invoke the service.
  EOT
  type = map(object({
    auth_type          = optional(string, "NONE")
    custom_domain_name = optional(string)
    certificate_arn    = optional(string)
    principals         = optional(list(string), [])
    target_group = object({
      type             = optional(string, "IP")
      ip_address_type  = optional(string, "IPV4")
      port             = number
      protocol         = optional(string, "HTTPS")
      protocol_version = optional(string, "HTTP1")
      health_check = optional(object({
        path                = optional(string, "/")
        interval            = optional(number, 30)
        timeout             = optional(number, 5)
        healthy_threshold   = optional(number, 3)
        unhealthy_threshold = optional(number, 3)
        matcher             = optional(string, "200-299")
      }), {})
    })
  }))
  default = {}
}

###############################################################################
# DNS + logging
###############################################################################
variable "create_dns_records" {
  description = "Create CNAME records mapping each service's custom_domain_name to its generated Lattice DNS name. Requires route53_zone_id."
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route 53 zone ID in which to create the services' CNAME records. Required when create_dns_records = true."
  type        = string
  default     = null
}

variable "enable_access_logs" {
  description = "Create a CloudWatch Logs group per service and subscribe Lattice access logs to it."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Retention, in days, for each service's access-log group."
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
