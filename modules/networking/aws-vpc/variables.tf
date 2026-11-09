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

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, keyed by availability zone (e.g. { \"ap-southeast-1a\" = \"10.0.0.0/24\" })."
  type        = map(string)
}

variable "app_subnet_cidrs" {
  description = "Private application subnet CIDRs, keyed by availability zone. Routed to the internet via NAT."
  type        = map(string)
}

variable "isolated_subnet_cidrs" {
  description = "Isolated subnet CIDRs (e.g. databases), keyed by availability zone."
  type        = map(string)
  default     = {}
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway so the app/isolated subnets can reach the internet."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
