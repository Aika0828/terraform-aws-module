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
# Distribution
###############################################################################
variable "comment" {
  description = "Comment shown on the CloudFront distribution. Null falls back to a generated description."
  type        = string
  default     = null
}

variable "enabled" {
  description = "Whether the distribution accepts end-user requests."
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "Enable IPv6 on the distribution."
  type        = bool
  default     = false
}

variable "price_class" {
  description = "CloudFront price class: PriceClass_All, PriceClass_200 or PriceClass_100."
  type        = string
  default     = "PriceClass_100"
}

variable "aliases" {
  description = "Alternate domain names (CNAMEs) served by the distribution."
  type        = list(string)
  default     = []
}

variable "default_root_object" {
  description = "Object returned for requests to the root URL (e.g. index.html). Null for none."
  type        = string
  default     = null
}

variable "web_acl_id" {
  description = "ARN of a WAFv2 web ACL (or ID of a WAF Classic ACL) to associate. Null for none."
  type        = string
  default     = null
}

###############################################################################
# VPC origin (optional) — created from an Application Load Balancer, etc.
###############################################################################
variable "vpc_origin" {
  description = "When set, creates a CloudFront VPC origin and adds it as a distribution origin. `arn` is the ALB/NLB/EC2 ARN; `domain_name` is the origin's DNS name."
  type = object({
    arn                    = string
    domain_name            = string
    origin_id              = optional(string, "vpc-origin")
    http_port              = optional(number, 80)
    https_port             = optional(number, 443)
    origin_protocol_policy = optional(string, "http-only")
    origin_ssl_protocols   = optional(list(string), ["TLSv1.2"])
  })
  default = null
}

###############################################################################
# Additional (non-VPC) origins
###############################################################################
variable "origins" {
  description = "Additional origins for the distribution (e.g. S3 or custom HTTP origins)."
  type = list(object({
    origin_id                = string
    domain_name              = string
    origin_path              = optional(string)
    origin_access_control_id = optional(string)
    custom_origin_config = optional(object({
      http_port              = optional(number, 80)
      https_port             = optional(number, 443)
      origin_protocol_policy = optional(string, "https-only")
      origin_ssl_protocols   = optional(list(string), ["TLSv1.2"])
    }))
  }))
  default = []
}

###############################################################################
# Cache behavior
###############################################################################
variable "default_cache_behavior" {
  description = "Default cache behavior. target_origin_id must match a VPC origin or an entry in `origins`."
  type = object({
    target_origin_id           = string
    allowed_methods            = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cached_methods             = optional(list(string), ["GET", "HEAD"])
    viewer_protocol_policy     = optional(string, "redirect-to-https")
    compress                   = optional(bool, true)
    cache_policy_id            = optional(string)
    origin_request_policy_id   = optional(string)
    response_headers_policy_id = optional(string)
  })
}

###############################################################################
# Viewer certificate
###############################################################################
variable "certificate_arn" {
  description = "ACM certificate ARN (in us-east-1) for the aliases. Null uses the default *.cloudfront.net certificate."
  type        = string
  default     = null
}

variable "minimum_protocol_version" {
  description = "Minimum TLS version viewers may use when certificate_arn is set."
  type        = string
  default     = "TLSv1.2_2021"
}

###############################################################################
# Geo restriction
###############################################################################
variable "geo_restriction" {
  description = "Geographic restriction for the distribution."
  type = object({
    restriction_type = optional(string, "none") # none, whitelist, blacklist
    locations        = optional(list(string), [])
  })
  default = {}
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto the distribution, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
