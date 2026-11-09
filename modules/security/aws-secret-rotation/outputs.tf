output "function_arn" {
  description = "ARN of the rotation Lambda."
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the rotation Lambda."
  value       = aws_lambda_function.this.function_name
}

output "log_group_name" {
  description = "CloudWatch log group for the rotation Lambda."
  value       = aws_cloudwatch_log_group.this.name
}

output "rotated_secret_ids" {
  description = "Secret IDs that rotation was configured for."
  value       = [for r in aws_secretsmanager_secret_rotation.this : r.secret_id]
}
