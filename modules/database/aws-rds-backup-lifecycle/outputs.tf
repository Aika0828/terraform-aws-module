output "lambda_function_arn" {
  description = "ARN of the snapshot-lifecycle Lambda function."
  value       = aws_lambda_function.this.arn
}

output "lambda_function_name" {
  description = "Name of the snapshot-lifecycle Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "log_group_name" {
  description = "CloudWatch log group for the Lambda function."
  value       = aws_cloudwatch_log_group.this.name
}

output "create_rule_arn" {
  description = "ARN of the EventBridge rule that triggers snapshot creation."
  value       = aws_cloudwatch_event_rule.create.arn
}

output "cleanup_rule_arn" {
  description = "ARN of the EventBridge rule that triggers snapshot cleanup."
  value       = aws_cloudwatch_event_rule.cleanup.arn
}

output "snapshot_prefix" {
  description = "Identifier prefix applied to every managed snapshot."
  value       = local.snapshot_prefix
}

output "sns_topic_arn" {
  description = "ARN of the failure-alert SNS topic (null when create_sns_topic = false)."
  value       = try(aws_sns_topic.alerts[0].arn, null)
}
