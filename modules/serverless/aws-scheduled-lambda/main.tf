locals {
  name = "${var.project_name}-${var.environment}"

  function_name = "${local.name}-${var.function_name}"

  build_archive = var.source_dir != null || var.source_file != null
  use_s3        = var.s3_bucket != null

  local_filename = local.build_archive ? data.archive_file.this[0].output_path : var.filename
}

###############################################################################
# Deployment package
###############################################################################
data "archive_file" "this" {
  count = local.build_archive ? 1 : 0

  type        = "zip"
  source_dir  = var.source_dir
  source_file = var.source_file
  output_path = "${path.module}/.terraform-build/${var.function_name}.zip"
}

###############################################################################
# Function + log group
###############################################################################
resource "aws_cloudwatch_log_group" "this" {
  #checkov:skip=CKV_AWS_338:Log retention is environment-driven (retention_in_days); not pinned in a reusable module
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id

  tags = merge(var.tags, { Name = "/aws/lambda/${local.function_name}" })
}

resource "aws_lambda_function" "this" {
  #checkov:skip=CKV_AWS_115:Lambda reserved concurrency is per-workload tuning left to the consumer
  #checkov:skip=CKV_AWS_116:Lambda DLQ target is consumer-supplied via dead_letter_config
  #checkov:skip=CKV_AWS_173:Lambda env-var CMK is consumer-supplied via kms_key_arn
  #checkov:skip=CKV_AWS_272:Lambda code-signing config is consumer-supplied
  #checkov:skip=CKV_AWS_50:X-Ray tracing is consumer-configurable via tracing_config
  function_name = local.function_name
  role          = var.role_arn
  handler       = var.handler
  runtime       = var.runtime
  memory_size   = var.memory_size
  timeout       = var.timeout
  architectures = var.architectures
  layers        = length(var.layers) > 0 ? var.layers : null

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

###############################################################################
# EventBridge schedule
###############################################################################
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${local.function_name}-schedule"
  description         = "Scheduled invocation of ${local.function_name}"
  schedule_expression = var.schedule_expression
  state               = var.schedule_enabled ? "ENABLED" : "DISABLED"

  tags = merge(var.tags, { Name = "${local.function_name}-schedule" })
}

resource "aws_cloudwatch_event_target" "schedule" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "${local.function_name}-target"
  arn       = aws_lambda_function.this.arn
  input     = var.event_input
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

###############################################################################
# Optional failure alerting: SNS topic + CloudWatch alarm on Errors
###############################################################################
resource "aws_sns_topic" "alerts" {
  count = var.enable_error_alarm ? 1 : 0

  name              = "${local.function_name}-alerts"
  kms_master_key_id = var.sns_kms_master_key_id

  tags = merge(var.tags, { Name = "${local.function_name}-alerts" })
}

resource "aws_sns_topic_subscription" "alerts" {
  for_each = var.enable_error_alarm ? toset(var.alarm_subscription_emails) : toset([])

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_cloudwatch_metric_alarm" "errors" {
  count = var.enable_error_alarm ? 1 : 0

  alarm_name        = "${local.function_name}-errors"
  alarm_description = "Invocation errors for the ${local.function_name} Lambda."
  namespace         = "AWS/Lambda"
  metric_name       = "Errors"
  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }
  statistic           = "Sum"
  period              = var.alarm_period
  evaluation_periods  = var.alarm_evaluation_periods
  threshold           = var.alarm_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts[0].arn]
  ok_actions    = [aws_sns_topic.alerts[0].arn]

  tags = merge(var.tags, { Name = "${local.function_name}-errors" })
}
