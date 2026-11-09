output "api_id" {
  description = "ID of the API Gateway v2 API."
  value       = aws_apigatewayv2_api.this.id
}

output "api_arn" {
  description = "ARN of the API."
  value       = aws_apigatewayv2_api.this.arn
}

output "api_endpoint" {
  description = "Default endpoint URL of the API."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "execution_arn" {
  description = "Execution ARN of the API, used when granting Lambda invoke permission."
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "stage_id" {
  description = "ID of the deployed stage."
  value       = aws_apigatewayv2_stage.this.id
}

output "stage_invoke_url" {
  description = "Invoke URL of the deployed stage."
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "authorizer_id" {
  description = "ID of the Lambda authorizer, or null when none was created."
  value       = var.authorizer != null ? aws_apigatewayv2_authorizer.this[0].id : null
}
