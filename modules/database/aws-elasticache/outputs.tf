output "replication_group_id" {
  description = "The ElastiCache replication group identifier."
  value       = aws_elasticache_replication_group.this.id
}

output "arn" {
  description = "ARN of the replication group."
  value       = aws_elasticache_replication_group.this.arn
}

output "primary_endpoint_address" {
  description = "Address of the primary (write) endpoint."
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Address of the reader (read-only) endpoint."
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "port" {
  description = "Port Redis listens on."
  value       = aws_elasticache_replication_group.this.port
}

output "security_group_id" {
  description = "ID of the security group created for the replication group."
  value       = aws_security_group.this.id
}

output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group."
  value       = aws_elasticache_subnet_group.this.name
}
