###############################################################################
# Identity
###############################################################################
variable "project_name" {
  description = "Project / application identifier, used as the first part of every resource name."
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
# Networking
###############################################################################
variable "vpc_id" {
  description = "VPC in which to create the target group and security group."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets the load balancer is attached to."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "Provide at least one subnet ID."
  }
}

variable "internal" {
  description = "Create an internal (true) or internet-facing (false) load balancer."
  type        = bool
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing on the NLB."
  type        = bool
  default     = true
}

###############################################################################
# Ingress to the NLB security group (on the listener ports)
###############################################################################
variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the listeners."
  type        = list(string)
  default     = []
}

variable "ingress_prefix_list_ids" {
  description = "Managed prefix list IDs allowed to reach the listeners."
  type        = list(string)
  default     = []
}

variable "ingress_security_group_ids" {
  description = "Security groups allowed to reach the listeners."
  type        = list(string)
  default     = []
}

###############################################################################
# Listeners (each forwards to the module's target group)
###############################################################################
variable "listeners" {
  description = "Listeners to create. Each forwards to the target group. Use protocol TLS with certificate_arn for TLS termination at the NLB."
  type = list(object({
    port            = number
    protocol        = optional(string, "TCP")
    certificate_arn = optional(string)
    ssl_policy      = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
  }))
  default = [{ port = 80, protocol = "TCP" }]

  validation {
    condition     = length(var.listeners) >= 1
    error_message = "Provide at least one listener."
  }

  validation {
    condition     = alltrue([for l in var.listeners : contains(["TCP", "UDP", "TCP_UDP", "TLS"], l.protocol)])
    error_message = "Each listener protocol must be TCP, UDP, TCP_UDP or TLS."
  }

  validation {
    condition     = alltrue([for l in var.listeners : l.protocol != "TLS" || l.certificate_arn != null])
    error_message = "A TLS listener requires certificate_arn."
  }
}

###############################################################################
# Target group
###############################################################################
variable "target_group" {
  description = "Target group configuration. Omit health_check to use the default TCP health check."
  type = object({
    port                 = number
    protocol             = optional(string, "TCP")
    target_type          = optional(string, "ip")
    deregistration_delay = optional(number, 300)
    preserve_client_ip   = optional(bool)
    health_check = optional(object({
      protocol            = optional(string, "TCP")
      port                = optional(string, "traffic-port")
      path                = optional(string)
      matcher             = optional(string)
      interval            = optional(number, 30)
      timeout             = optional(number)
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
    }))
  })
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
