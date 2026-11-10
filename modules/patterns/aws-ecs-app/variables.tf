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
# Networking + cluster (supplied — this composite creates none of them)
###############################################################################
variable "vpc_id" {
  description = "VPC the service and load balancer run in."
  type        = string
}

variable "app_subnet_ids" {
  description = "Private subnets for the tasks (and the ALB)."
  type        = list(string)
}

variable "cluster_arn" {
  description = "ECS cluster ARN (from aws-ecs-cluster)."
  type        = string
}

###############################################################################
# IAM (supplied — this composite creates no IAM)
###############################################################################
variable "execution_role_arn" {
  description = "ECS task execution role ARN."
  type        = string
}

variable "task_role_arn" {
  description = "ECS task role ARN."
  type        = string
}

###############################################################################
# Container
###############################################################################
variable "container_name" {
  description = "Primary container name."
  type        = string
  default     = "app"
}

variable "container_port" {
  description = "Container (and target group) port."
  type        = number
  default     = 8080
}

variable "image_tag" {
  description = "Image tag deployed from the module-created ECR repo."
  type        = string
  default     = "latest"
}

variable "task_cpu" {
  description = "Task CPU units."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Task memory (MiB)."
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Number of task copies."
  type        = number
  default     = 1
}

variable "environment_variables" {
  description = "Plain environment variables for the container."
  type        = map(string)
  default     = {}
}

variable "enable_execute_command" {
  description = "Enable ECS Exec into tasks."
  type        = bool
  default     = true
}

variable "capacity_provider" {
  description = "Capacity provider for the service."
  type        = string
  default     = "FARGATE"
}

###############################################################################
# ECR
###############################################################################
variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability: MUTABLE or IMMUTABLE. Defaults to IMMUTABLE so published tags cannot be overwritten; set MUTABLE if your workflow reuses tags."
  type        = string
  default     = "IMMUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Scan images on push."
  type        = bool
  default     = true
}

variable "ecr_force_delete" {
  description = "Allow deleting the ECR repo even if it contains images."
  type        = bool
  default     = false
}

###############################################################################
# ALB (optional)
###############################################################################
variable "create_alb" {
  description = "Create an ALB in front of the service."
  type        = bool
  default     = true
}

variable "alb_internal" {
  description = "Make the ALB internal (true) or internet-facing (false)."
  type        = bool
  default     = true
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the ALB listener."
  type        = list(string)
  default     = []
}

variable "alb_ingress_prefix_list_ids" {
  description = "Prefix list IDs allowed to reach the ALB listener."
  type        = list(string)
  default     = []
}

variable "alb_ingress_security_group_ids" {
  description = "Security groups allowed to reach the ALB listener."
  type        = list(string)
  default     = []
}

variable "health_check_path" {
  description = "Target group health check path."
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Extra tags merged onto every resource, on top of the provider default_tags and the module's Name tag."
  type        = map(string)
  default     = {}
}
