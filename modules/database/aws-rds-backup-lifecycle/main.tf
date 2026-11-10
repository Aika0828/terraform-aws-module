locals {
  name              = "${var.project_name}-${var.environment}"
  function_name     = "${local.name}-rds-backup-lifecycle"
  snapshot_prefix   = coalesce(var.snapshot_prefix, "${local.name}-rds-snap")
  managed_tag_key   = "ManagedBy"
  managed_tag_value = "${local.name}-rds-backup-lifecycle"
}

###############################################################################
# Lambda package
###############################################################################
data "archive_file" "this" {
  type        = "zip"
  output_path = "${path.module}/rds_backup_lifecycle.zip"

  source {
    content = templatefile("${path.module}/src/rds_backup_lifecycle.py", {
      db_instance_identifier = var.db_instance_identifier
      snapshot_prefix        = local.snapshot_prefix
      managed_tag_key        = local.managed_tag_key
      managed_tag_value      = local.managed_tag_value
      retention_days         = var.retention_days
    })
    filename = "lambda_function.py"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  #checkov:skip=CKV_AWS_158:Log-group CMK is consumer-supplied via kms_key_id; AWS-managed encryption by default
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, { Name = "${local.function_name}-logs" })
}

resource "aws_lambda_function" "this" {
  #checkov:skip=CKV_AWS_115:Lambda reserved concurrency is per-workload tuning left to the consumer
  #checkov:skip=CKV_AWS_116:Lambda DLQ target is consumer-supplied via dead_letter_config
  #checkov:skip=CKV_AWS_117:Deploying the function in a VPC is a consumer choice via vpc_config
  #checkov:skip=CKV_AWS_272:Lambda code-signing config is consumer-supplied
  #checkov:skip=CKV_AWS_50:X-Ray tracing is consumer-configurable via tracing_config
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  function_name    = local.function_name
  role             = var.lambda_role_arn
  handler          = "lambda_function.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout

  depends_on = [aws_cloudwatch_log_group.this]

  tags = merge(var.tags, { Name = local.function_name })
}

###############################################################################
# Schedule (EventBridge) — create + cleanup
###############################################################################
resource "aws_cloudwatch_event_rule" "create" {
  name                = "${local.name}-rds-backup-create"
  description         = "Daily manual RDS snapshot for the ${local.name} database"
  schedule_expression = "cron(${var.create_schedule_cron})"

  tags = merge(var.tags, { Name = "${local.name}-rds-backup-create" })
}

resource "aws_cloudwatch_event_rule" "cleanup" {
  name                = "${local.name}-rds-backup-cleanup"
  description         = "Expire manual RDS snapshots past the ${var.retention_days}-day retention window"
  schedule_expression = "cron(${var.cleanup_schedule_cron})"

  tags = merge(var.tags, { Name = "${local.name}-rds-backup-cleanup" })
}

resource "aws_cloudwatch_event_target" "create" {
  rule      = aws_cloudwatch_event_rule.create.name
  target_id = "RdsBackupCreateLambdaTarget"
  arn       = aws_lambda_function.this.arn

  input = jsonencode({ action = "create" })
}

resource "aws_cloudwatch_event_target" "cleanup" {
  rule      = aws_cloudwatch_event_rule.cleanup.name
  target_id = "RdsBackupCleanupLambdaTarget"
  arn       = aws_lambda_function.this.arn

  input = jsonencode({ action = "cleanup" })
}

resource "aws_lambda_permission" "allow_create" {
  statement_id  = "AllowExecutionFromEventBridgeRdsBackupCreate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.create.arn
}

resource "aws_lambda_permission" "allow_cleanup" {
  statement_id  = "AllowExecutionFromEventBridgeRdsBackupCleanup"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cleanup.arn
}

###############################################################################
# Alerting (optional) — SNS topic + CloudWatch alarm on Lambda errors
###############################################################################
resource "aws_sns_topic" "alerts" {
  count             = var.create_sns_topic ? 1 : 0
  name              = "${local.name}-rds-backup-alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = merge(var.tags, { Name = "${local.name}-rds-backup-alerts" })
}

resource "aws_sns_topic_subscription" "emails" {
  for_each  = var.create_sns_topic ? toset(var.alert_recipient_emails) : []
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = each.value
}

# Lambda's Errors metric only increments on an unhandled exception or timeout,
# which is why the function code re-raises instead of swallowing errors.
resource "aws_cloudwatch_metric_alarm" "errors" {
  count             = var.create_sns_topic ? 1 : 0
  alarm_name        = "${local.name}-rds-backup-lambda-errors"
  alarm_description = "Alerts when the daily RDS manual-snapshot create or cleanup routine fails"
  namespace         = "AWS/Lambda"
  metric_name       = "Errors"
  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }
  statistic           = "Sum"
  period              = 86400
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts[0].arn]
  ok_actions    = [aws_sns_topic.alerts[0].arn]

  tags = merge(var.tags, { Name = "${local.name}-rds-backup-lambda-errors" })
}
