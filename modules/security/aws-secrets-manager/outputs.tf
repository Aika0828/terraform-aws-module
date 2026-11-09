output "secret_arns" {
  description = "Map of secret logical key to the secret's ARN."
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
  sensitive   = true
}

output "secret_ids" {
  description = "Map of secret logical key to the secret's ID."
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.id }
}

output "secret_names" {
  description = "Map of secret logical key to the secret's full name."
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.name }
}

output "version_ids" {
  description = "Map of secret logical key to the created secret version ID (only for secrets that received a value)."
  value       = { for k, v in aws_secretsmanager_secret_version.this : k => v.version_id }
}
