output "cluster_identifier" {
  description = "The Aurora cluster identifier."
  value       = aws_rds_cluster.this.cluster_identifier
}

output "cluster_arn" {
  description = "The ARN of the Aurora cluster."
  value       = aws_rds_cluster.this.arn
}

output "cluster_resource_id" {
  description = "The stable, immutable resource ID of the cluster (for IAM auth policies)."
  value       = aws_rds_cluster.this.cluster_resource_id
}

output "endpoint" {
  description = "Writer endpoint for the cluster."
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Load-balanced reader endpoint for the cluster."
  value       = aws_rds_cluster.this.reader_endpoint
}

output "port" {
  description = "Port the cluster listens on."
  value       = aws_rds_cluster.this.port
}

output "database_name" {
  description = "Name of the initial database."
  value       = aws_rds_cluster.this.database_name
}

output "master_username" {
  description = "Master username for the cluster."
  value       = aws_rds_cluster.this.master_username
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed master password secret (null when manage_master_user_password = false)."
  value       = try(aws_rds_cluster.this.master_user_secret[0].secret_arn, null)
  sensitive   = true
}

output "security_group_id" {
  description = "ID of the security group created for the cluster."
  value       = aws_security_group.this.id
}

output "subnet_group_name" {
  description = "Name of the DB subnet group."
  value       = aws_db_subnet_group.this.name
}

output "instance_identifiers" {
  description = "Identifiers of the cluster instances (writer first)."
  value       = aws_rds_cluster_instance.this[*].identifier
}
