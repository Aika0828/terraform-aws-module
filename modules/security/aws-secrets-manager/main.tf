locals {
  name = "${var.project_name}-${var.environment}"

  # A version is written only when the caller supplies a value or asks for a
  # generated one; otherwise the secret is created empty for an external owner.
  secrets_with_value = {
    for k, v in var.secrets : k => v if v.generate_random || v.secret_string != null
  }
}

# Generated values come from the Secrets Manager GetRandomPassword API, so no
# third-party random provider is needed.
data "aws_secretsmanager_random_password" "this" {
  for_each = { for k, v in var.secrets : k => v if v.generate_random }

  password_length     = each.value.random_password_length
  exclude_punctuation = each.value.exclude_punctuation
}

resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name                    = "${local.name}-${each.value.name}"
  description             = each.value.description
  recovery_window_in_days = each.value.recovery_window_in_days

  tags = merge(var.tags, { Name = "${local.name}-${each.value.name}" })
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each = local.secrets_with_value

  secret_id = aws_secretsmanager_secret.this[each.key].id
  secret_string = (
    each.value.generate_random
    ? data.aws_secretsmanager_random_password.this[each.key].random_password
    : each.value.secret_string
  )
}
