output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function (for API Gateway / integrations)."
  value       = aws_lambda_function.this.invoke_arn
}

output "qualified_arn" {
  description = "Version-qualified ARN of the Lambda function."
  value       = aws_lambda_function.this.qualified_arn
}

output "version" {
  description = "Latest published version of the Lambda function."
  value       = aws_lambda_function.this.version
}

output "log_group_name" {
  description = "Name of the function's CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "ARN of the function's CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.arn
}
