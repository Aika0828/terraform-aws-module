locals {
  cluster_name = coalesce(var.name, "${var.project_name}-${var.environment}-cluster")
}

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = var.container_insights
  }

  dynamic "configuration" {
    for_each = var.execute_command_configuration != null ? [var.execute_command_configuration] : []
    content {
      execute_command_configuration {
        kms_key_id = configuration.value.kms_key_id
        logging    = configuration.value.logging

        dynamic "log_configuration" {
          for_each = configuration.value.log_configuration != null ? [configuration.value.log_configuration] : []
          content {
            cloud_watch_encryption_enabled = log_configuration.value.cloud_watch_encryption_enabled
            cloud_watch_log_group_name     = log_configuration.value.cloud_watch_log_group_name
            s3_bucket_name                 = log_configuration.value.s3_bucket_name
            s3_bucket_encryption_enabled   = log_configuration.value.s3_bucket_encryption_enabled
            s3_key_prefix                  = log_configuration.value.s3_key_prefix
          }
        }
      }
    }
  }

  dynamic "service_connect_defaults" {
    for_each = var.service_connect_namespace_arn != null ? [var.service_connect_namespace_arn] : []
    content {
      namespace = service_connect_defaults.value
    }
  }

  tags = merge(var.tags, { Name = local.cluster_name })
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count = length(var.capacity_providers) > 0 ? 1 : 0

  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight            = default_capacity_provider_strategy.value.weight
      base              = default_capacity_provider_strategy.value.base
    }
  }
}
