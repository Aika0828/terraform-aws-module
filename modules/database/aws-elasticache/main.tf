locals {
  name = "${var.project_name}-${var.environment}"
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${local.name}-redis"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { Name = "${local.name}-redis" })
}

resource "aws_security_group" "this" {
  name        = "${local.name}-redis-sg"
  description = "Access to the ${local.name} Redis replication group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${local.name}-redis-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "from_sg" {
  for_each                     = toset(var.allowed_security_group_ids)
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value
  from_port                    = var.port
  to_port                      = var.port
  ip_protocol                  = "tcp"
  description                  = "Redis access from security group ${each.value}"
}

resource "aws_vpc_security_group_ingress_rule" "from_cidr" {
  for_each          = toset(var.allowed_cidr_blocks)
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = each.value
  from_port         = var.port
  to_port           = var.port
  ip_protocol       = "tcp"
  description       = "Redis access from CIDR ${each.value}"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

resource "aws_elasticache_replication_group" "this" {
  #checkov:skip=CKV_AWS_191:ElastiCache CMK is consumer-supplied via kms_key_id
  replication_group_id = "${local.name}-redis"
  description          = "Redis for ${var.project_name} in ${var.environment}"

  engine             = "redis"
  engine_version     = var.engine_version
  node_type          = var.node_type
  num_cache_clusters = var.num_cache_clusters
  port               = var.port

  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.this.id]
  parameter_group_name = var.parameter_group_name

  automatic_failover_enabled = var.num_cache_clusters > 1
  multi_az_enabled           = var.num_cache_clusters > 1

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.auth_token

  snapshot_retention_limit = var.snapshot_retention_limit

  tags = merge(var.tags, { Name = "${local.name}-redis" })

  lifecycle {
    precondition {
      condition     = var.auth_token == null || var.transit_encryption_enabled
      error_message = "auth_token requires transit_encryption_enabled = true."
    }
  }
}
