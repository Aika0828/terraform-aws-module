locals {
  name = "${var.project_name}-${var.environment}"
}

resource "aws_ssm_parameter" "this" {
  for_each = var.parameters

  name        = var.path_prefix != null ? "${var.path_prefix}/${each.value.name}" : "${local.name}-${each.value.name}"
  type        = each.value.type
  description = each.value.description
  tier        = each.value.tier
  key_id      = each.value.type == "SecureString" ? each.value.key_id : null

  # SecureString values are secrets; mark them so they never surface in plan
  # output or logs. The AWS provider also treats the attribute as sensitive.
  value = each.value.type == "SecureString" ? sensitive(each.value.value) : each.value.value

  tags = merge(var.tags, { Name = "${local.name}-${each.value.name}" })
}
