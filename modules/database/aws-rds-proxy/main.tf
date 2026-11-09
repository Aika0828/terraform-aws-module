locals {
  name = "${var.project_name}-${var.environment}"

  # Security groups attached to the proxy: the one created here (if any) plus any passed in.
  proxy_security_group_ids = concat(
    var.create_security_group ? [aws_security_group.this[0].id] : [],
    var.vpc_security_group_ids,
  )
}

###############################################################################
# Security group (optional — modern rule resources)
###############################################################################
resource "aws_security_group" "this" {
  count       = var.create_security_group ? 1 : 0
  name        = "${local.name}-rds-proxy-sg"
  description = "Access to the ${local.name} RDS proxy"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${local.name}-rds-proxy-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "from_sg" {
  for_each                     = var.create_security_group ? toset(var.allowed_security_group_ids) : []
  security_group_id            = aws_security_group.this[0].id
  referenced_security_group_id = each.value
  from_port                    = var.port
  to_port                      = var.port
  ip_protocol                  = "tcp"
  description                  = "Proxy access from security group ${each.value}"
}

resource "aws_vpc_security_group_ingress_rule" "from_cidr" {
  for_each          = var.create_security_group ? toset(var.allowed_cidr_blocks) : []
  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = each.value
  from_port         = var.port
  to_port           = var.port
  ip_protocol       = "tcp"
  description       = "Proxy access from CIDR ${each.value}"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  count             = var.create_security_group ? 1 : 0
  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

###############################################################################
# Proxy
###############################################################################
resource "aws_db_proxy" "this" {
  name                   = "${local.name}-rds-proxy"
  engine_family          = var.engine_family
  role_arn               = var.role_arn
  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = local.proxy_security_group_ids

  require_tls         = var.require_tls
  debug_logging       = var.debug_logging
  idle_client_timeout = var.idle_client_timeout

  dynamic "auth" {
    for_each = toset(var.secret_arns)
    content {
      auth_scheme = "SECRETS"
      iam_auth    = var.iam_auth
      secret_arn  = auth.value
    }
  }

  tags = merge(var.tags, { Name = "${local.name}-rds-proxy" })

  lifecycle {
    precondition {
      condition     = (var.db_cluster_identifier != null) != (var.db_instance_identifier != null)
      error_message = "Set exactly one of db_cluster_identifier or db_instance_identifier."
    }
  }
}

resource "aws_db_proxy_default_target_group" "this" {
  db_proxy_name = aws_db_proxy.this.name

  connection_pool_config {
    connection_borrow_timeout    = var.connection_borrow_timeout
    max_connections_percent      = var.max_connections_percent
    max_idle_connections_percent = var.max_idle_connections_percent
  }
}

resource "aws_db_proxy_target" "this" {
  db_proxy_name          = aws_db_proxy.this.name
  target_group_name      = aws_db_proxy_default_target_group.this.name
  db_cluster_identifier  = var.db_cluster_identifier
  db_instance_identifier = var.db_instance_identifier
}
