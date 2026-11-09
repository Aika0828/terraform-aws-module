locals {
  name = "${var.project_name}-${var.environment}"
}

###############################################################################
# ECR repository for the app image
###############################################################################
resource "aws_ecr_repository" "app" {
  name                 = "${local.name}-app"
  image_tag_mutability = var.ecr_image_tag_mutability
  force_delete         = var.ecr_force_delete

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  tags = merge(var.tags, { Name = "${local.name}-app" })
}

###############################################################################
# Load balancer (optional)
###############################################################################
module "alb" {
  count  = var.create_alb ? 1 : 0
  source = "../../loadbalancer/aws-alb"

  project_name = var.project_name
  environment  = var.environment

  vpc_id     = var.vpc_id
  subnet_ids = var.app_subnet_ids
  internal   = var.alb_internal

  ingress_cidr_blocks        = var.alb_ingress_cidr_blocks
  ingress_prefix_list_ids    = var.alb_ingress_prefix_list_ids
  ingress_security_group_ids = var.alb_ingress_security_group_ids

  target_group = {
    port = var.container_port
    health_check = {
      path = var.health_check_path
    }
  }

  tags = var.tags
}

###############################################################################
# ECS service
###############################################################################
module "service" {
  source = "../../compute/aws-ecs-service"

  project_name = var.project_name
  environment  = var.environment

  cluster_arn        = var.cluster_arn
  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

  container_name  = var.container_name
  container_image = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
  container_port  = var.container_port
  task_cpu        = var.task_cpu
  task_memory     = var.task_memory
  desired_count   = var.desired_count

  environment_variables  = var.environment_variables
  enable_execute_command = var.enable_execute_command
  capacity_provider      = var.capacity_provider

  vpc_id                     = var.vpc_id
  subnet_ids                 = var.app_subnet_ids
  ingress_security_group_ids = var.create_alb ? [module.alb[0].security_group_id] : []
  target_group_arn           = var.create_alb ? module.alb[0].target_group_arn : null

  tags = var.tags
}
