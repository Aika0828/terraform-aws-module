locals {
  name         = "${var.project_name}-${var.environment}"
  service_name = coalesce(var.name, "${local.name}-service")

  container_environment = [
    for k, v in var.environment_variables : { name = k, value = v }
  ]
}

data "aws_region" "current" {
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.name}"
  retention_in_days = var.log_retention_in_days

  tags = merge(var.tags, { Name = "/ecs/${local.name}" })
}

###############################################################################
# Service security group
###############################################################################
resource "aws_security_group" "this" {
  name        = "${local.name}-ecs-sg"
  description = "Access to the ${local.name} ECS tasks"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${local.name}-ecs-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "from_sg" {
  for_each                     = toset(var.ingress_security_group_ids)
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  description                  = "Container access from security group ${each.value}"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

###############################################################################
# Task definition
###############################################################################
resource "aws_ecs_task_definition" "this" {
  family                   = "${local.name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {
    cpu_architecture        = var.cpu_architecture
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = local.container_environment
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = var.container_name
        }
      }
    }
  ])

  tags = merge(var.tags, { Name = "${local.name}-task" })
}

###############################################################################
# Service
###############################################################################
resource "aws_ecs_service" "this" {
  name                   = local.service_name
  cluster                = var.cluster_arn
  task_definition        = aws_ecs_task_definition.this.arn
  desired_count          = var.desired_count
  enable_execute_command = var.enable_execute_command

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider
    weight            = 1
    base              = 0
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = concat([aws_security_group.this.id], var.additional_security_group_ids)
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [var.target_group_arn] : []
    content {
      target_group_arn = load_balancer.value
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  tags = merge(var.tags, { Name = local.service_name })
}
