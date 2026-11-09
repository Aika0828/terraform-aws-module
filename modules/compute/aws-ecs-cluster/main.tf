locals {
  cluster_name = coalesce(var.name, "${var.project_name}-${var.environment}-cluster")
}

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = var.container_insights
  }

  tags = merge(var.tags, { Name = local.cluster_name })
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = var.capacity_providers

  default_capacity_provider_strategy {
    weight            = 1
    capacity_provider = var.default_capacity_provider
  }
}
