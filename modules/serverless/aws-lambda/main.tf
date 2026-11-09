locals {
  name = "${var.project_name}-${var.environment}"

  function_name = "${local.name}-${var.function_name}"

  # A deployment package is built locally only when a source directory or file
  # is supplied; otherwise the package comes from a pre-built zip or from S3.
  build_archive = var.source_dir != null || var.source_file != null

  use_s3 = var.s3_bucket != null

  # Resolve the local package path: generated archive takes precedence, then a
  # caller-supplied pre-built zip.
  local_filename = local.build_archive ? data.archive_file.this[0].output_path : var.filename
}

data "archive_file" "this" {
  count = local.build_archive ? 1 : 0

  type        = "zip"
  source_dir  = var.source_dir
  source_file = var.source_file
  output_path = "${path.module}/.terraform-build/${var.function_name}.zip"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id

  tags = merge(var.tags, { Name = "/aws/lambda/${local.function_name}" })
}

resource "aws_lambda_function" "this" {
  function_name = local.function_name
  role          = var.role_arn
  handler       = var.handler
  runtime       = var.runtime
  memory_size   = var.memory_size
  timeout       = var.timeout
  architectures = var.architectures
  layers        = length(var.layers) > 0 ? var.layers : null

  # Package source: S3 object, or a local zip (generated or pre-built).
  s3_bucket         = local.use_s3 ? var.s3_bucket : null
  s3_key            = local.use_s3 ? var.s3_key : null
  s3_object_version = local.use_s3 ? var.s3_object_version : null
  filename          = local.use_s3 ? null : local.local_filename
  source_code_hash  = local.build_archive ? data.archive_file.this[0].output_base64sha256 : null

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  tags = merge(var.tags, { Name = local.function_name })

  # The log group is created with the chosen retention before the function, so
  # Lambda does not auto-create an unmanaged, never-expiring one.
  depends_on = [aws_cloudwatch_log_group.this]

  lifecycle {
    precondition {
      condition = length([
        for s in [local.build_archive, var.filename != null, local.use_s3] : s if s
      ]) == 1
      error_message = "Provide exactly one package source: source_dir/source_file, filename, or s3_bucket + s3_key."
    }

    precondition {
      condition     = !local.use_s3 || var.s3_key != null
      error_message = "s3_key is required when s3_bucket is set."
    }
  }
}
