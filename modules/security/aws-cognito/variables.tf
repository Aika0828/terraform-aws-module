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
# User pool
###############################################################################
variable "allow_admin_create_user_only" {
  description = "When true, only administrators can create users (self sign-up is disabled)."
  type        = bool
  default     = true
}

variable "domain_prefix" {
  description = "Cognito hosted-UI domain prefix (must be globally unique). Null skips creating a hosted-UI domain."
  type        = string
  default     = null
}

variable "resource_servers" {
  description = <<-EOT
    Map of OAuth resource servers to create. Each key is a logical name; the value
    defines the resource server identifier, display name, and its custom scopes.
  EOT

  type = map(object({
    identifier = string
    name       = string
    scopes = optional(list(object({
      scope_name        = string
      scope_description = string
    })), [])
  }))
  default = {}
}

variable "user_pool_clients" {
  description = <<-EOT
    Map of user pool clients to create. Each key is a suffix for the client name; the
    value configures its OAuth behaviour and the scopes it is granted.
  EOT

  type = map(object({
    generate_secret                      = optional(bool, true)
    allowed_oauth_flows_user_pool_client = optional(bool, true)
    allowed_oauth_flows                  = optional(list(string), [])
    allowed_oauth_scopes                 = optional(list(string), [])
    callback_urls                        = optional(list(string), [])
    logout_urls                          = optional(list(string), [])
    supported_identity_providers         = optional(list(string), ["COGNITO"])
    explicit_auth_flows                  = optional(list(string), null)
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
