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

variable "vpc_id" {
  description = "VPC in which to create the load balancer and target group."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets the load balancer is attached to."
  type        = list(string)
}

variable "internal" {
  description = "Create an internal (true) or internet-facing (false) load balancer."
  type        = bool
  default     = true
}

###############################################################################
# Ingress to the ALB security group (on the listener port)
###############################################################################
variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the listener."
  type        = list(string)
  default     = []
}

variable "ingress_prefix_list_ids" {
  description = "Managed prefix list IDs allowed to reach the listener (e.g. the CloudFront origin-facing prefix list)."
  type        = list(string)
  default     = []
}

variable "ingress_security_group_ids" {
  description = "Security groups allowed to reach the listener."
  type        = list(string)
  default     = []
}

###############################################################################
# Listener
###############################################################################
variable "listener_port" {
  description = "Port the listener accepts traffic on."
  type        = number
  default     = 80
}

variable "listener_protocol" {
  description = "Listener protocol: HTTP or HTTPS."
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.listener_protocol)
    error_message = "listener_protocol must be HTTP or HTTPS."
  }
}

variable "certificate_arn" {
  description = "ACM certificate ARN. Required when listener_protocol = HTTPS."
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy for an HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

###############################################################################
# Target group
###############################################################################
variable "target_group" {
  description = "Target group configuration."
  type = object({
    port                 = number
    protocol             = optional(string, "HTTP")
    target_type          = optional(string, "ip")
    deregistration_delay = optional(number, 300)
    health_check = optional(object({
      path                = optional(string, "/")
      protocol            = optional(string, "HTTP")
      matcher             = optional(string, "200")
      interval            = optional(number, 30)
      timeout             = optional(number, 5)
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
    }), {})
  })
}

variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
