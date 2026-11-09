output "certificate_arn" {
  description = "ARN of the issued ACM certificate. When DNS validation is automated, this resolves after validation completes."
  value       = var.zone_id != null && var.validation_method == "DNS" ? aws_acm_certificate_validation.this[0].certificate_arn : aws_acm_certificate.this.arn
}

output "certificate_id" {
  description = "ID (ARN) of the ACM certificate resource."
  value       = aws_acm_certificate.this.id
}

output "domain_name" {
  description = "Primary domain name on the certificate."
  value       = aws_acm_certificate.this.domain_name
}

output "domain_validation_options" {
  description = "Validation options for each domain (name, type, value) — useful when creating validation records externally."
  value       = aws_acm_certificate.this.domain_validation_options
}

output "status" {
  description = "Status of the certificate (e.g. PENDING_VALIDATION, ISSUED)."
  value       = aws_acm_certificate.this.status
}
