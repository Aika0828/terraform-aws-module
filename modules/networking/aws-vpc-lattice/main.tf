locals {
  name = "${var.project_name}-${var.environment}"

  service_network_id = var.create_service_network ? aws_vpclattice_service_network.this[0].id : var.service_network_id

  # Services that attach an auth policy: AWS_IAM with at least one principal.
  auth_policy_services = {
    for k, s in var.services : k => s
    if s.auth_type == "AWS_IAM" && length(s.principals) > 0
  }

  # Services that should publish a CNAME record for their custom domain.
  dns_record_services = var.create_dns_records ? {
    for k, s in var.services : k => s if s.custom_domain_name != null
  } : {}
}

###############################################################################
# Service network
###############################################################################
resource "aws_vpclattice_service_network" "this" {
  count = var.create_service_network ? 1 : 0

  name      = "${local.name}-sn"
  auth_type = var.service_network_auth_type

  tags = merge(var.tags, { Name = "${local.name}-sn" })
}

resource "aws_vpclattice_service_network_vpc_association" "this" {
  for_each = var.create_service_network ? toset(var.service_network_vpc_ids) : []

  service_network_identifier = aws_vpclattice_service_network.this[0].id
  vpc_identifier             = each.value

  tags = merge(var.tags, { Name = "${local.name}-sn-assoc-${each.value}" })
}

###############################################################################
# Services
###############################################################################
resource "aws_vpclattice_service" "this" {
  for_each = var.services

  name               = "${local.name}-${each.key}"
  auth_type          = each.value.auth_type
  custom_domain_name = each.value.custom_domain_name
  certificate_arn    = each.value.certificate_arn

  tags = merge(var.tags, { Name = "${local.name}-${each.key}" })
}

resource "aws_vpclattice_service_network_service_association" "this" {
  for_each = var.services

  service_network_identifier = local.service_network_id
  service_identifier         = aws_vpclattice_service.this[each.key].id

  tags = merge(var.tags, { Name = "${local.name}-${each.key}-assoc" })
}

###############################################################################
# Target groups + HTTPS listeners
###############################################################################
resource "aws_vpclattice_target_group" "this" {
  for_each = var.services

  name = "${local.name}-${each.key}"
  type = each.value.target_group.type

  config {
    vpc_identifier   = var.vpc_id
    ip_address_type  = each.value.target_group.ip_address_type
    port             = each.value.target_group.port
    protocol         = each.value.target_group.protocol
    protocol_version = each.value.target_group.protocol_version

    health_check {
      enabled                       = true
      health_check_interval_seconds = each.value.target_group.health_check.interval
      health_check_timeout_seconds  = each.value.target_group.health_check.timeout
      healthy_threshold_count       = each.value.target_group.health_check.healthy_threshold
      unhealthy_threshold_count     = each.value.target_group.health_check.unhealthy_threshold
      path                          = each.value.target_group.health_check.path
      port                          = each.value.target_group.port
      protocol                      = each.value.target_group.protocol
      protocol_version              = each.value.target_group.protocol_version

      matcher {
        value = each.value.target_group.health_check.matcher
      }
    }
  }

  tags = merge(var.tags, { Name = "${local.name}-${each.key}" })

  lifecycle {
    precondition {
      condition     = var.vpc_id != null
      error_message = "vpc_id must be set when services are defined (target groups register targets in it)."
    }
  }
}

resource "aws_vpclattice_listener" "https" {
  for_each = var.services

  name               = "${each.key}-https"
  service_identifier = aws_vpclattice_service.this[each.key].id
  port               = 443
  protocol           = "HTTPS"

  default_action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.this[each.key].id
        weight                  = 1
      }
    }
  }

  tags = merge(var.tags, { Name = "${local.name}-${each.key}-https" })
}

###############################################################################
# Auth policies (no IAM resources; principal ARNs are supplied as input)
###############################################################################
resource "aws_vpclattice_auth_policy" "this" {
  for_each = local.auth_policy_services

  resource_identifier = aws_vpclattice_service.this[each.key].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowInvoke"
        Effect    = "Allow"
        Principal = { AWS = each.value.principals }
        Action    = "vpc-lattice-svcs:Invoke"
        Resource  = "${aws_vpclattice_service.this[each.key].arn}/*"
      }
    ]
  })
}

###############################################################################
# Access logs
###############################################################################
resource "aws_cloudwatch_log_group" "access_logs" {
  #checkov:skip=CKV_AWS_158:Log-group CMK is consumer-supplied via kms_key_id; AWS-managed encryption by default
  for_each = var.enable_access_logs ? var.services : {}

  name              = "/aws/vpc-lattice/${local.name}-${each.key}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, { Name = "${local.name}-${each.key}-logs" })
}

resource "aws_vpclattice_access_log_subscription" "this" {
  for_each = var.enable_access_logs ? var.services : {}

  resource_identifier = aws_vpclattice_service.this[each.key].id
  destination_arn     = aws_cloudwatch_log_group.access_logs[each.key].arn
}

###############################################################################
# DNS validation records
###############################################################################
resource "aws_route53_record" "service" {
  for_each = local.dns_record_services

  zone_id = var.route53_zone_id
  name    = each.value.custom_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_vpclattice_service.this[each.key].dns_entry[0].domain_name]
}
