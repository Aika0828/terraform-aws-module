output "domain_name" {
  description = "Name of the OpenSearch domain."
  value       = aws_opensearch_domain.this.domain_name
}

output "domain_arn" {
  description = "ARN of the OpenSearch domain."
  value       = aws_opensearch_domain.this.arn
}

output "domain_id" {
  description = "Unique identifier of the OpenSearch domain."
  value       = aws_opensearch_domain.this.domain_id
}

output "endpoint" {
  description = "Domain-specific HTTPS endpoint used to submit index and search requests."
  value       = aws_opensearch_domain.this.endpoint
}

output "dashboard_endpoint" {
  description = "Endpoint for the OpenSearch Dashboards."
  value       = aws_opensearch_domain.this.dashboard_endpoint
}

output "port" {
  description = "Port the HTTPS endpoint listens on."
  value       = var.port
}

output "master_username" {
  description = "Master username for the internal user database."
  value       = var.master_username
}

output "security_group_id" {
  description = "ID of the security group created for the domain."
  value       = aws_security_group.this.id
}
