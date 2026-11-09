output "zone_id" {
  description = "ID of the hosted zone records are written to (created or existing)."
  value       = local.zone_id
}

output "zone_name" {
  description = "Name of the created hosted zone (null when create_zone = false)."
  value       = try(aws_route53_zone.this[0].name, null)
}

output "zone_arn" {
  description = "ARN of the created hosted zone (null when create_zone = false)."
  value       = try(aws_route53_zone.this[0].arn, null)
}

output "name_servers" {
  description = "Authoritative name servers for the created public hosted zone (null when create_zone = false)."
  value       = try(aws_route53_zone.this[0].name_servers, null)
}

output "record_fqdns" {
  description = "Fully-qualified domain names of the created records, keyed by record name."
  value       = { for k, r in aws_route53_record.this : k => r.fqdn }
}
