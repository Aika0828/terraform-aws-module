output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function."
  value       = aws_lambda_function.this.invoke_arn
}

output "log_group_name" {
  description = "Name of the function's CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "ARN of the function's CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.arn
}

output "event_rule_arn" {
  description = "ARN of the EventBridge schedule rule."
  value       = aws_cloudwatch_event_rule.schedule.arn
}

output "event_rule_name" {
  description = "Name of the EventBridge schedule rule."
  value       = aws_cloudwatch_event_rule.schedule.name
}

output "sns_topic_arn" {
  description = "ARN of the failure-alert SNS topic, or null when error alarming is disabled."
  value       = var.enable_error_alarm ? aws_sns_topic.alerts[0].arn : null
}

output "error_alarm_arn" {
  description = "ARN of the CloudWatch error alarm, or null when error alarming is disabled."
  value       = var.enable_error_alarm ? aws_cloudwatch_metric_alarm.errors[0].arn : null
}
