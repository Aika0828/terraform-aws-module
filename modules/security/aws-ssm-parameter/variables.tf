###############################################################################
# Identity
###############################################################################
variable "project_name" {
  description = "Project identifier, used as the first part of every parameter name."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, uat, prod). Used in parameter names."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.environment))
    error_message = "environment must be lowercase alphanumeric (e.g. dev, uat, prod)."
  }
}

variable "path_prefix" {
  description = "Optional leading path for every parameter name, e.g. /my-project/dev. When null, parameters are named <project>-<environment>-<name>."
  type        = string
  default     = null
}

###############################################################################
# Parameters
###############################################################################
variable "parameters" {
  description = <<-EOT
    Map of SSM parameters to create. The map key is a stable logical identifier
    (used in outputs and state addresses); the object configures one parameter:
      - name        : suffix combined with the module prefix to form the parameter name.
      - type        : String, SecureString, or StringList.
      - value       : parameter value. SecureString values are stored encrypted and
                      are treated as sensitive by the AWS provider.
      - description : human-readable description of the parameter.
      - tier        : Standard, Advanced, or Intelligent-Tiering.
      - key_id      : KMS key ID/ARN for SecureString encryption (null uses the account default key).
  EOT

  type = map(object({
    name        = string
    type        = string
    value       = string
    description = optional(string, null)
    tier        = optional(string, "Standard")
    key_id      = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in values(var.parameters) : contains(["String", "SecureString", "StringList"], p.type)
    ])
    error_message = "Each parameter type must be one of: String, SecureString, StringList."
  }

  validation {
    condition = alltrue([
      for p in values(var.parameters) : contains(["Standard", "Advanced", "Intelligent-Tiering"], p.tier)
    ])
    error_message = "Each parameter tier must be one of: Standard, Advanced, Intelligent-Tiering."
  }
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto every parameter, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
