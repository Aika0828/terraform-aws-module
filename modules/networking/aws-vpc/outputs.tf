output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs keyed by availability zone."
  value       = { for az, s in aws_subnet.public : az => s.id }
}

output "private_subnet_ids" {
  description = "Private subnet IDs keyed by availability zone."
  value       = { for az, s in aws_subnet.private : az => s.id }
}

output "isolated_subnet_ids" {
  description = "Isolated subnet IDs keyed by availability zone."
  value       = { for az, s in aws_subnet.isolated : az => s.id }
}

output "public_subnet_id_list" {
  description = "Public subnet IDs as a list (for modules that take list(string))."
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_id_list" {
  description = "Private subnet IDs as a list (for modules that take list(string))."
  value       = [for s in aws_subnet.private : s.id]
}

output "isolated_subnet_id_list" {
  description = "Isolated subnet IDs as a list (for modules that take list(string))."
  value       = [for s in aws_subnet.isolated : s.id]
}

output "internet_gateway_id" {
  description = "ID of the internet gateway."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway (null when enable_nat_gateway = false)."
  value       = try(aws_nat_gateway.this[0].id, null)
}
