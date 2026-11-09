locals {
  name = "${var.project_name}-${var.environment}"

  # Zone the records are written to: the one we create, or an existing one.
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : var.zone_id
}

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0

  name    = var.zone.name
  comment = var.zone.comment

  dynamic "vpc" {
    for_each = var.zone.private ? toset(var.zone.vpc_ids) : []
    content {
      vpc_id = vpc.value
    }
  }

  tags = merge(var.tags, { Name = "${local.name}-${var.zone.name}" })

  lifecycle {
    precondition {
      condition     = !var.create_zone || var.zone != null
      error_message = "zone must be set when create_zone = true."
    }
  }
}

resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = local.zone_id
  name    = each.value.name
  type    = each.value.type

  # Simple record: ttl + records. Omitted for alias records.
  ttl     = each.value.alias == null ? each.value.ttl : null
  records = each.value.records

  dynamic "alias" {
    for_each = each.value.alias == null ? [] : [each.value.alias]
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  lifecycle {
    precondition {
      condition     = var.create_zone || var.zone_id != null
      error_message = "zone_id must be set when create_zone = false."
    }
  }
}
