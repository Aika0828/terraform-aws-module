locals {
  name        = "${var.project_name}-${var.environment}"
  domain_name = "${local.name}-search"

  master_password = jsondecode(
    data.aws_secretsmanager_secret_version.master.secret_string
  )[var.master_password_secret_json_key]

  default_access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = "es:*"
        Resource  = "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.domain_name}/*"
      }
    ]
  })

  access_policies = coalesce(var.access_policies, local.default_access_policies)
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret_version" "master" {
  secret_id = var.master_password_secret_arn
}

###############################################################################
# Networking
###############################################################################
resource "aws_security_group" "this" {
  name        = "${local.name}-opensearch-sg"
  description = "Access to the ${local.name} OpenSearch domain"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${local.name}-opensearch-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "from_sg" {
  for_each                     = toset(var.allowed_security_group_ids)
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value
  from_port                    = var.port
  to_port                      = var.port
  ip_protocol                  = "tcp"
  description                  = "HTTPS access from security group ${each.value}"
}

resource "aws_vpc_security_group_ingress_rule" "from_cidr" {
  for_each          = toset(var.allowed_cidr_blocks)
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = each.value
  from_port         = var.port
  to_port           = var.port
  ip_protocol       = "tcp"
  description       = "HTTPS access from CIDR ${each.value}"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

###############################################################################
# Logging
###############################################################################
resource "aws_cloudwatch_log_group" "this" {
  #checkov:skip=CKV_AWS_158:Log-group CMK is consumer-supplied via kms_key_id; AWS-managed encryption by default
  #checkov:skip=CKV_AWS_338:Log retention is environment-driven (retention_in_days); not pinned in a reusable module
  count = var.log_publishing_enabled ? 1 : 0

  name              = "/aws/OpenSearchService/domains/${local.domain_name}/search-logs"
  retention_in_days = var.log_retention_in_days

  tags = merge(var.tags, { Name = "${local.name}-opensearch-logs" })
}

resource "aws_cloudwatch_log_resource_policy" "this" {
  count = var.log_publishing_enabled ? 1 : 0

  policy_name = "${local.name}-opensearch-logs"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowOpenSearchService"
        Effect    = "Allow"
        Principal = { Service = "es.amazonaws.com" }
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ]
        Resource = "${aws_cloudwatch_log_group.this[0].arn}:*"
      }
    ]
  })
}

###############################################################################
# Domain
###############################################################################
resource "aws_opensearch_domain" "this" {
  #checkov:skip=CKV_AWS_247:OpenSearch at-rest CMK is consumer-supplied
  #checkov:skip=CKV_AWS_317:OpenSearch audit logging requires a consumer-provided log destination
  #checkov:skip=CKV_AWS_318:Dedicated master-node count is a per-environment HA/cost choice
  domain_name    = local.domain_name
  engine_version = var.engine_version

  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.instance_count
    zone_awareness_enabled = var.zone_awareness_enabled

    dynamic "zone_awareness_config" {
      for_each = var.zone_awareness_enabled ? [1] : []
      content {
        availability_zone_count = var.availability_zone_count
      }
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.ebs_volume_size
    volume_type = var.ebs_volume_type
  }

  node_to_node_encryption {
    enabled = true
  }

  encrypt_at_rest {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  vpc_options {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.this.id]
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = var.master_username
      master_user_password = local.master_password
    }
  }

  dynamic "log_publishing_options" {
    for_each = var.log_publishing_enabled ? [1] : []
    content {
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.this[0].arn
      enabled                  = true
      log_type                 = "SEARCH_SLOW_LOGS"
    }
  }

  access_policies = local.access_policies

  tags = merge(var.tags, { Name = local.domain_name })
}
