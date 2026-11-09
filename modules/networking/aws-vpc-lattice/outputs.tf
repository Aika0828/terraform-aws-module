output "service_network_id" {
  description = "ID of the service network services are associated with (created or existing)."
  value       = local.service_network_id
}

output "service_network_arn" {
  description = "ARN of the created service network (null when create_service_network = false)."
  value       = try(aws_vpclattice_service_network.this[0].arn, null)
}

output "service_ids" {
  description = "VPC Lattice service IDs keyed by service name."
  value       = { for k, s in aws_vpclattice_service.this : k => s.id }
}

output "service_arns" {
  description = "VPC Lattice service ARNs keyed by service name."
  value       = { for k, s in aws_vpclattice_service.this : k => s.arn }
}

output "service_dns_names" {
  description = "Generated Lattice DNS name for each service, keyed by service name."
  value       = { for k, s in aws_vpclattice_service.this : k => s.dns_entry[0].domain_name }
}

output "target_group_ids" {
  description = "Target group IDs keyed by service name."
  value       = { for k, t in aws_vpclattice_target_group.this : k => t.id }
}

output "target_group_arns" {
  description = "Target group ARNs keyed by service name."
  value       = { for k, t in aws_vpclattice_target_group.this : k => t.arn }
}
