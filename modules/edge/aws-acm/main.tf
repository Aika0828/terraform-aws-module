locals {
  name = "${var.project_name}-${var.environment}"

  # Deduplicated validation options, keyed by the domain they validate, so that
  # a cert covering apex + wildcard produces exactly one record per name.
  validation_options = var.zone_id != null && var.validation_method == "DNS" ? {
    for dvo in aws_acm_certificate.this.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }...
  } : {}
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = var.validation_method
  key_algorithm             = var.key_algorithm

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, { Name = "${local.name}-cert" })
}

# DNS validation records, created only when a hosted zone is supplied.
resource "aws_route53_record" "validation" {
  for_each = local.validation_options

  zone_id         = var.zone_id
  name            = each.value[0].name
  type            = each.value[0].type
  records         = [each.value[0].record]
  ttl             = var.validation_record_ttl
  allow_overwrite = true
}

# Block until ACM observes the records and issues the certificate.
resource "aws_acm_certificate_validation" "this" {
  count = var.zone_id != null && var.validation_method == "DNS" ? 1 : 0

  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}
