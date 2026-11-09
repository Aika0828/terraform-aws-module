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
# Secrets
###############################################################################
variable "secrets" {
  description = <<-EOT
    Map of secrets to create in Secrets Manager. The map key is a stable logical
    identifier (used in outputs and state addresses); the object configures one
    secret:
      - name                    : suffix appended to "<project>-<environment>-" to form the secret name.
      - description             : human-readable description of the secret.
      - secret_string           : the value to store. May be a plain string or a pre-encoded JSON string.
      - generate_random         : when true, a random value is generated (via the Secrets Manager
                                   GetRandomPassword API) and stored instead of secret_string.
      - random_password_length  : length of the generated value when generate_random = true.
      - exclude_punctuation     : exclude punctuation from the generated value when generate_random = true.
      - recovery_window_in_days : days Secrets Manager retains the secret after deletion (0 = delete immediately).
    A secret version is created only when secret_string is set or generate_random = true.
  EOT

  type = map(object({
    name                    = string
    description             = optional(string, null)
    secret_string           = optional(string, null)
    generate_random         = optional(bool, false)
    random_password_length  = optional(number, 32)
    exclude_punctuation     = optional(bool, true)
    recovery_window_in_days = optional(number, 30)
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
