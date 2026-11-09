output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard, or null when none was created."
  value       = var.dashboard_body != null ? aws_cloudwatch_dashboard.this[0].dashboard_arn : null
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard, or null when none was created."
  value       = var.dashboard_body != null ? aws_cloudwatch_dashboard.this[0].dashboard_name : null
}

output "alarm_arns" {
  description = "Map of alarm name -> ARN for the created metric alarms."
  value       = { for k, a in aws_cloudwatch_metric_alarm.this : k => a.arn }
}

output "alarm_ids" {
  description = "Map of alarm name -> ID for the created metric alarms."
  value       = { for k, a in aws_cloudwatch_metric_alarm.this : k => a.id }
}
