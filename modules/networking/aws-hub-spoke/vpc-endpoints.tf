locals {
  region = split(":", aws_vpc.this.arn)[3]

  # All workload route tables a gateway endpoint should be reachable from.
  gateway_endpoint_route_table_ids = concat(
    [for rt in aws_route_table.private : rt.id],
    [for rt in aws_route_table.database : rt.id],
    [for rt in aws_route_table.vpc_endpoint : rt.id],
  )

  create_endpoint_sg = length(var.interface_endpoint_services) > 0
}

###############################################################################
# Security group for interface endpoints
###############################################################################
resource "aws_security_group" "vpc_endpoint" {
  count = local.create_endpoint_sg ? 1 : 0

  name        = "${local.name}-vpce-sg"
  description = "HTTPS access from the VPC to interface VPC endpoints"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${local.name}-vpce-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_https" {
  count = local.create_endpoint_sg ? 1 : 0

  security_group_id = aws_security_group.vpc_endpoint[0].id
  cidr_ipv4         = aws_vpc.this.cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS from within the VPC"
}

resource "aws_vpc_security_group_egress_rule" "vpc_endpoint_all" {
  count = local.create_endpoint_sg ? 1 : 0

  security_group_id = aws_security_group.vpc_endpoint[0].id
  cidr_ipv4         = aws_vpc.this.cidr_block
  ip_protocol       = "-1"
  description       = "All outbound within the VPC"
}

###############################################################################
# Gateway endpoints (e.g. S3, DynamoDB)
###############################################################################
resource "aws_vpc_endpoint" "gateway" {
  for_each = toset(var.gateway_endpoint_services)

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${local.region}.${each.value}"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = local.gateway_endpoint_route_table_ids

  tags = merge(var.tags, { Name = "${local.name}-vpce-${each.value}" })
}

###############################################################################
# Interface endpoints (e.g. ECR, SSM, Secrets Manager)
###############################################################################
resource "aws_vpc_endpoint" "interface" {
  for_each = toset(var.interface_endpoint_services)

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${local.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.vpc_endpoint : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoint[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${local.name}-vpce-${replace(each.value, ".", "-")}" })
}
