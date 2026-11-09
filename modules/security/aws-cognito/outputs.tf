output "user_pool_id" {
  description = "The Cognito user pool ID."
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "The ARN of the Cognito user pool."
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_endpoint" {
  description = "The endpoint of the Cognito user pool."
  value       = aws_cognito_user_pool.this.endpoint
}

output "domain" {
  description = "The hosted-UI domain URL, or null when no domain is configured."
  value = (
    var.domain_prefix != null
    ? "https://${aws_cognito_user_pool_domain.this[0].domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
    : null
  )
}

output "client_ids" {
  description = "Map of app-client key to its client ID."
  value       = { for k, v in aws_cognito_user_pool_client.this : k => v.id }
}

output "client_secrets" {
  description = "Map of app-client key to its client secret (empty for clients created without a secret)."
  value       = { for k, v in aws_cognito_user_pool_client.this : k => v.client_secret }
  sensitive   = true
}
