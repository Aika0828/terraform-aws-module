locals {
  name          = "${var.project_name}-${var.environment}"
  function_name = coalesce(var.name, "${local.name}-secret-rotation")

  use_archive  = var.source_dir != null || var.source_file != null
  package_zip  = var.source_dir != null ? "${path.module}/.build/${local.function_name}-dir.zip" : "${path.module}/.build/${local.function_name}-file.zip"
  package_path = local.use_archive ? local.package_zip : var.filename
}

data "archive_file" "this" {
  count = local.use_archive ? 1 : 0

  type        = "zip"
  output_path = local.package_zip
  source_dir  = var.source_dir
  source_file = var.source_file
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_in_days

  tags = merge(var.tags, { Name = "/aws/lambda/${local.function_name}" })
}

resource "aws_lambda_function" "this" {
  function_name = local.function_name
  role          = var.role_arn
  runtime       = var.runtime
  handler       = var.handler
  memory_size   = var.memory_size
  timeout       = var.timeout

  filename         = local.package_path
  source_code_hash = local.use_archive ? data.archive_file.this[0].output_base64sha256 : null
  s3_bucket        = var.s3_bucket
  s3_key           = var.s3_key

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.vpc_subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  tags = merge(var.tags, { Name = local.function_name })

  depends_on = [aws_cloudwatch_log_group.this]

  lifecycle {
    precondition {
      condition     = length([for s in [var.source_dir, var.source_file, var.filename, var.s3_bucket] : s if s != null]) == 1
      error_message = "Supply exactly one package source: source_dir, source_file, filename, or s3_bucket (+ s3_key)."
    }
  }
}

# Allow Secrets Manager to invoke the rotation function, scoped per secret.
resource "aws_lambda_permission" "secretsmanager" {
  for_each = toset(var.secret_arns)

  statement_id  = "AllowRotation-${substr(md5(each.value), 0, 8)}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = each.value
}

resource "aws_secretsmanager_secret_rotation" "this" {
  for_each = toset(var.secret_arns)

  secret_id           = each.value
  rotation_lambda_arn = aws_lambda_function.this.arn

  rotation_rules {
    automatically_after_days = var.rotation_automatically_after_days
    duration                 = var.rotation_duration
  }

  depends_on = [aws_lambda_permission.secretsmanager]
}
