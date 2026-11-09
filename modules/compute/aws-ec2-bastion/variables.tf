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
  description = "VPC in which to create the bastion's security group."
  type        = string
}

variable "subnet_id" {
  description = "Subnet in which to launch the bastion instance."
  type        = string
}

variable "associate_public_ip" {
  description = "Associate a public IP with the bastion. Keep false when access is via SSM Session Manager only."
  type        = bool
  default     = false
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH (port 22) to the bastion. Leave empty for SSM-only access."
  type        = list(string)
  default     = []
}

variable "allowed_ssh_security_group_ids" {
  description = "Security groups allowed to SSH (port 22) to the bastion."
  type        = list(string)
  default     = []
}

###############################################################################
# Instance
###############################################################################
variable "instance_type" {
  description = "EC2 instance type for the bastion."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for the bastion. Leave null to resolve the latest Amazon Linux 2023 AMI from SSM (see ami_ssm_parameter_name)."
  type        = string
  default     = null
}

variable "ami_ssm_parameter_name" {
  description = "SSM public parameter that resolves the AMI when ami_id is null. Defaults to the latest x86_64 Amazon Linux 2023 AMI."
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "iam_instance_profile" {
  description = "Name of an existing IAM instance profile to attach (e.g. for SSM Session Manager). This module creates no IAM resources. Null attaches none."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH. Null uses no key pair (SSM-only access)."
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script for the bastion. Null leaves it unset."
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Size in GiB of the root EBS volume."
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of the root EBS volume."
  type        = string
  default     = "gp3"
}

variable "ebs_optimized" {
  description = "Enable EBS optimization on the instance."
  type        = bool
  default     = true
}

variable "monitoring" {
  description = "Enable detailed CloudWatch monitoring on the instance."
  type        = bool
  default     = true
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
