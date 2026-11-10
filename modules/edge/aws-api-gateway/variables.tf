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
# API
###############################################################################
variable "protocol_type" {
  description = "API protocol: HTTP or WEBSOCKET."
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "WEBSOCKET"], var.protocol_type)
    error_message = "protocol_type must be HTTP or WEBSOCKET."
  }
}

variable "stage_name" {
  description = "Name of the deployed stage. Null defaults to the environment."
  type        = string
  default     = null
}

variable "cors_configuration" {
  description = "Optional CORS configuration for an HTTP API."
  type = object({
    allow_origins     = optional(list(string))
    allow_methods     = optional(list(string))
    allow_headers     = optional(list(string))
    expose_headers    = optional(list(string))
    allow_credentials = optional(bool)
    max_age           = optional(number)
  })
  default = null
}

###############################################################################
# Routes + integrations
###############################################################################
variable "routes" {
  description = "Routes to create. Each wires a route_key to an integration (typically a Lambda invoke ARN)."
  type = list(object({
    route_key              = string
    integration_uri        = string
    integration_type       = optional(string, "AWS_PROXY")
    integration_method     = optional(string, "POST")
    payload_format_version = optional(string, "2.0")
    connection_type        = optional(string, "INTERNET")
    authorization_type     = optional(string, "NONE") # NONE, CUSTOM, JWT, AWS_IAM
  }))
  default = []
}

###############################################################################
# Authorizer (optional) — ARN only; this module creates no IAM
###############################################################################
variable "authorizer" {
  description = "Optional Lambda (REQUEST) authorizer. authorizer_uri is the authorizer Lambda's invoke ARN. Routes with authorization_type = CUSTOM use it."
  type = object({
    authorizer_uri                    = string
    name                              = optional(string, "custom-authorizer")
    authorizer_type                   = optional(string, "REQUEST")
    identity_sources                  = optional(list(string), ["$request.header.Authorization"])
    authorizer_payload_format_version = optional(string, "2.0")
    authorizer_result_ttl_in_seconds  = optional(number, 0)
    enable_simple_responses           = optional(bool, true)
  })
  default = null
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
