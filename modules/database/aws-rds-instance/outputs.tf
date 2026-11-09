output "db_instance_identifier" {
  description = "The RDS instance identifier."
  value       = aws_db_instance.this.identifier
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance."
  value       = aws_db_instance.this.arn
}

output "db_instance_resource_id" {
  description = "The stable, immutable resource ID of the instance (for IAM auth policies)."
  value       = aws_db_instance.this.resource_id
}

output "endpoint" {
  description = "Connection endpoint in address:port form."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "Hostname of the instance."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port the instance listens on."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Name of the initial database."
  value       = aws_db_instance.this.db_name
}

output "master_username" {
  description = "Master username for the instance."
  value       = aws_db_instance.this.username
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed master password secret (null when manage_master_user_password = false)."
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
  sensitive   = true
}

output "security_group_id" {
  description = "ID of the security group created for the instance."
  value       = aws_security_group.this.id
}

output "subnet_group_name" {
  description = "Name of the DB subnet group."
  value       = aws_db_subnet_group.this.name
}
