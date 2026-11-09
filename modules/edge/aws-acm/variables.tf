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
# Certificate
###############################################################################
variable "domain_name" {
  description = "Fully qualified domain name to issue the certificate for (e.g. app.example.com)."
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names (SANs) to include on the certificate."
  type        = list(string)
  default     = []
}

variable "validation_method" {
  description = "How ACM validates domain ownership: DNS (recommended) or EMAIL."
  type        = string
  default     = "DNS"

  validation {
    condition     = contains(["DNS", "EMAIL"], var.validation_method)
    error_message = "validation_method must be DNS or EMAIL."
  }
}

variable "key_algorithm" {
  description = "Key algorithm for the certificate (e.g. RSA_2048, EC_prime256v1). Null uses the ACM default."
  type        = string
  default     = null
}

###############################################################################
# Route 53 validation (optional)
###############################################################################
variable "zone_id" {
  description = "Route 53 hosted zone ID in which to create DNS validation records. When set with validation_method = DNS, the module creates the validation records and waits for the certificate to be issued. Null skips automatic validation."
  type        = string
  default     = null
}

variable "validation_record_ttl" {
  description = "TTL (seconds) for the Route 53 DNS validation records."
  type        = number
  default     = 60
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
