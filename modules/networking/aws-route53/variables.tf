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
# Hosted zone
###############################################################################
variable "create_zone" {
  description = "Create a hosted zone. When false, records are created in the existing zone given by zone_id."
  type        = bool
  default     = true
}

variable "zone" {
  description = <<-EOT
    Hosted zone configuration, used when create_zone = true. Set private = true
    and provide vpc_ids to create a private hosted zone associated with those
    VPCs; leave private = false for a public zone.
  EOT
  type = object({
    name    = string
    private = optional(bool, false)
    comment = optional(string, "Managed by Terraform")
    vpc_ids = optional(list(string), [])
  })
  default = null

  validation {
    condition     = var.zone == null ? true : (!var.zone.private || length(var.zone.vpc_ids) > 0)
    error_message = "A private hosted zone (zone.private = true) requires at least one VPC in zone.vpc_ids."
  }
}

variable "zone_id" {
  description = "ID of an existing hosted zone to create records in. Required when create_zone = false."
  type        = string
  default     = null
}

###############################################################################
# Records
###############################################################################
variable "records" {
  description = <<-EOT
    DNS records to create, keyed by a unique name. For a simple record set
    `records` and `ttl`; for an alias (e.g. to an ALB or VPC Lattice service)
    set the `alias` object instead and leave `records`/`ttl` null.
  EOT
  type = map(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    records = optional(list(string))
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, false)
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for r in var.records : (r.alias != null) != (r.records != null)])
    error_message = "Each record must set exactly one of `records` or `alias`."
  }
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto the hosted zone, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
