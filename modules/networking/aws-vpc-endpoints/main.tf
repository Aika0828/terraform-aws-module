locals {
  name = "${var.project_name}-${var.environment}"

  managed_sg_ids = var.create_security_group ? [aws_security_group.this[0].id] : []
}

###############################################################################
# Managed security group for interface endpoints
###############################################################################
resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = "${local.name}-vpce-sg"
  description = "Shared security group for interface VPC endpoints"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${local.name}-vpce-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each = var.create_security_group ? toset(var.security_group_ingress_cidrs) : []

  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS from ${each.value}"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

###############################################################################
# Interface endpoints
###############################################################################
resource "aws_vpc_endpoint" "interface" {
  for_each = var.interface_endpoints

  vpc_id            = var.vpc_id
  service_name      = each.value.service_name
  vpc_endpoint_type = "Interface"

  subnet_ids = each.value.subnet_ids != null ? each.value.subnet_ids : var.default_subnet_ids
  security_group_ids = (
    each.value.security_group_ids != null ? each.value.security_group_ids : local.managed_sg_ids
  )
  private_dns_enabled = each.value.private_dns_enabled

  tags = merge(var.tags, { Name = "${local.name}-vpce-${each.key}" })
}

###############################################################################
# Gateway endpoints
###############################################################################
resource "aws_vpc_endpoint" "gateway" {
  for_each = var.gateway_endpoints

  vpc_id            = var.vpc_id
  service_name      = each.value.service_name
  vpc_endpoint_type = "Gateway"
  route_table_ids   = each.value.route_table_ids

  tags = merge(var.tags, { Name = "${local.name}-vpce-${each.key}" })
}
