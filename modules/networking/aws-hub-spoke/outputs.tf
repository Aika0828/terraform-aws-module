output "vpc_id" {
  description = "ID of the spoke VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the spoke VPC."
  value       = aws_vpc.this.cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs (list)."
  value       = [for s in aws_subnet.private : s.id]
}

output "database_subnet_ids" {
  description = "Database subnet IDs (list)."
  value       = [for s in aws_subnet.database : s.id]
}

output "transit_gateway_subnet_ids" {
  description = "Transit-gateway subnet IDs (list)."
  value       = [for s in aws_subnet.transit_gateway : s.id]
}

output "vpc_endpoint_subnet_ids" {
  description = "VPC-endpoint subnet IDs (list)."
  value       = [for s in aws_subnet.vpc_endpoint : s.id]
}

output "first_private_subnet_per_az_ids" {
  description = "One private subnet ID per availability zone (the index-0 subnet in each AZ)."
  value = [
    for az in distinct([for v in local.private_subnet_map : v.az_name]) :
    aws_subnet.private[one([
      for k, v in local.private_subnet_map : k if v.az_name == az && v.index == 0
    ])].id
  ]
}

output "private_route_table_ids" {
  description = "Private route table IDs (list)."
  value       = [for rt in aws_route_table.private : rt.id]
}

output "database_route_table_ids" {
  description = "Database route table IDs (list)."
  value       = [for rt in aws_route_table.database : rt.id]
}

output "transit_gateway_attachment_id" {
  description = "ID of the transit gateway VPC attachment (null when transit_gateway_id is empty)."
  value       = try(aws_ec2_transit_gateway_vpc_attachment.this[0].id, null)
}

output "vpc_endpoint_security_group_id" {
  description = "Security group ID attached to the interface VPC endpoints (null when none are created)."
  value       = try(aws_security_group.vpc_endpoint[0].id, null)
}

output "interface_endpoint_ids" {
  description = "Interface VPC endpoint IDs keyed by service short name."
  value       = { for k, e in aws_vpc_endpoint.interface : k => e.id }
}

output "gateway_endpoint_ids" {
  description = "Gateway VPC endpoint IDs keyed by service short name."
  value       = { for k, e in aws_vpc_endpoint.gateway : k => e.id }
}

output "flow_log_id" {
  description = "ID of the VPC flow log (null when enable_flow_logs = false)."
  value       = try(aws_flow_log.this[0].id, null)
}
