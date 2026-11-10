variable "project_name" {
  description = "Project identifier, used as the first part of every resource name."
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

variable "name" {
  description = "Override the service name. Null uses <project_name>-<environment>-service."
  type        = string
  default     = null
}

variable "cluster_arn" {
  description = "ARN (or id) of the ECS cluster to run in."
  type        = string
}

###############################################################################
# Task / container
###############################################################################
variable "container_name" {
  description = "Name of the primary container (also used as the log stream prefix and load balancer container name)."
  type        = string
}

variable "container_image" {
  description = "Container image reference (e.g. <ecr-url>:latest)."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 80
}

variable "task_cpu" {
  description = "Task-level CPU units (e.g. 512)."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Task-level memory in MiB (e.g. 1024)."
  type        = number
  default     = 1024
}

variable "cpu_architecture" {
  description = "CPU architecture: ARM64 or X86_64."
  type        = string
  default     = "ARM64"

  validation {
    condition     = contains(["ARM64", "X86_64"], var.cpu_architecture)
    error_message = "cpu_architecture must be ARM64 or X86_64."
  }
}

variable "execution_role_arn" {
  description = "IAM role ARN the ECS agent uses to pull images and write logs."
  type        = string
}

variable "task_role_arn" {
  description = "IAM role ARN assumed by the running container."
  type        = string
}

variable "environment_variables" {
  description = "Plain environment variables for the container, as a map."
  type        = map(string)
  default     = {}
}

###############################################################################
# Service
###############################################################################
variable "desired_count" {
  description = "Number of task copies to run."
  type        = number
  default     = 1
}

variable "capacity_provider" {
  description = "Capacity provider for the service (e.g. FARGATE, FARGATE_SPOT)."
  type        = string
  default     = "FARGATE"
}

variable "enable_execute_command" {
  description = "Enable ECS Exec (SSM) into running tasks."
  type        = bool
  default     = true
}

variable "target_group_arn" {
  description = "Target group ARN to register tasks with. Null leaves the service without a load balancer."
  type        = string
  default     = null
}

###############################################################################
# Networking
###############################################################################
variable "vpc_id" {
  description = "VPC for the service security group."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets the tasks run in (usually private subnets)."
  type        = list(string)
}

variable "ingress_security_group_ids" {
  description = "Security groups allowed to reach the container port (e.g. the ALB's security group)."
  type        = list(string)
  default     = []
}

variable "additional_security_group_ids" {
  description = "Extra security groups attached to the tasks."
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Assign a public IP to tasks (only valid in public subnets)."
  type        = bool
  default     = false
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention for the service log group."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
