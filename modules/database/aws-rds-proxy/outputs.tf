output "proxy_id" {
  description = "The RDS proxy identifier."
  value       = aws_db_proxy.this.id
}

output "proxy_arn" {
  description = "The ARN of the RDS proxy."
  value       = aws_db_proxy.this.arn
}

output "proxy_name" {
  description = "The name of the RDS proxy."
  value       = aws_db_proxy.this.name
}

output "endpoint" {
  description = "The endpoint applications connect to in place of the database endpoint."
  value       = aws_db_proxy.this.endpoint
}

output "port" {
  description = "Port the proxy listens on."
  value       = var.port
}

output "default_target_group_arn" {
  description = "ARN of the proxy's default target group."
  value       = aws_db_proxy_default_target_group.this.arn
}

output "security_group_id" {
  description = "ID of the security group created for the proxy (null when create_security_group = false)."
  value       = try(aws_security_group.this[0].id, null)
}
