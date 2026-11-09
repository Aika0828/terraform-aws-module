output "interface_endpoint_ids" {
  description = "Interface VPC endpoint IDs keyed by endpoint name."
  value       = { for k, e in aws_vpc_endpoint.interface : k => e.id }
}

output "gateway_endpoint_ids" {
  description = "Gateway VPC endpoint IDs keyed by endpoint name."
  value       = { for k, e in aws_vpc_endpoint.gateway : k => e.id }
}

output "interface_endpoint_dns_entries" {
  description = "DNS entries for each interface endpoint, keyed by endpoint name."
  value       = { for k, e in aws_vpc_endpoint.interface : k => e.dns_entry }
}

output "interface_endpoint_network_interface_ids" {
  description = "ENI IDs created for each interface endpoint, keyed by endpoint name."
  value       = { for k, e in aws_vpc_endpoint.interface : k => sort(tolist(e.network_interface_ids)) }
}

output "security_group_id" {
  description = "ID of the managed interface-endpoint security group (null when create_security_group = false)."
  value       = try(aws_security_group.this[0].id, null)
}
