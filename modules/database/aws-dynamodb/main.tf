locals {
  name       = "${var.project_name}-${var.environment}"
  table_name = "${local.name}-${var.table_name}"
}

resource "aws_dynamodb_table" "this" {
  #checkov:skip=CKV_AWS_119:CMK is consumer-supplied via kms_key_id; AWS-managed key used by default
  name         = local.table_name
  billing_mode = var.billing_mode
  hash_key     = var.hash_key
  range_key    = var.range_key

  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
      read_capacity      = var.billing_mode == "PROVISIONED" ? global_secondary_index.value.read_capacity : null
      write_capacity     = var.billing_mode == "PROVISIONED" ? global_secondary_index.value.write_capacity : null
    }
  }

  dynamic "ttl" {
    for_each = var.ttl == null ? [] : [var.ttl]
    content {
      attribute_name = ttl.value.attribute_name
      enabled        = ttl.value.enabled
    }
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery_enabled
  }

  server_side_encryption {
    enabled     = var.server_side_encryption.enabled
    kms_key_arn = var.server_side_encryption.kms_key_arn
  }

  tags = merge(var.tags, { Name = local.table_name })

  lifecycle {
    precondition {
      condition     = var.billing_mode != "PROVISIONED" || (var.read_capacity != null && var.write_capacity != null)
      error_message = "When billing_mode = PROVISIONED, read_capacity and write_capacity must be set."
    }
  }
}
