###############################################################################
# Private subnets
###############################################################################
resource "aws_subnet" "private" {
  for_each = local.private_subnet_map

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az_name

  tags = merge(var.tags, { Name = "${local.name}-private-${each.key}" })
}

resource "aws_route_table" "private" {
  for_each = local.private_subnet_map

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${local.name}-rtb-private-${each.key}" })
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnet_map

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route" "private_tgw" {
  for_each = local.attach_transit_gateway && var.transit_gateway_default_route ? aws_route_table.private : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.this]
}

###############################################################################
# Database subnets
###############################################################################
resource "aws_subnet" "database" {
  for_each = local.database_subnet_map

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az_name

  tags = merge(var.tags, { Name = "${local.name}-db-${each.key}" })
}

resource "aws_route_table" "database" {
  for_each = local.database_subnet_map

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${local.name}-rtb-db-${each.key}" })
}

resource "aws_route_table_association" "database" {
  for_each = local.database_subnet_map

  subnet_id      = aws_subnet.database[each.key].id
  route_table_id = aws_route_table.database[each.key].id
}

resource "aws_route" "database_tgw" {
  for_each = local.attach_transit_gateway && var.transit_gateway_default_route ? aws_route_table.database : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.this]
}

###############################################################################
# Transit gateway subnets
###############################################################################
resource "aws_subnet" "transit_gateway" {
  for_each = local.transit_gateway_subnet_map

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az_name

  tags = merge(var.tags, { Name = "${local.name}-tgw-${each.key}" })
}

resource "aws_route_table" "transit_gateway" {
  for_each = local.transit_gateway_subnet_map

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${local.name}-rtb-tgw-${each.key}" })
}

resource "aws_route_table_association" "transit_gateway" {
  for_each = local.transit_gateway_subnet_map

  subnet_id      = aws_subnet.transit_gateway[each.key].id
  route_table_id = aws_route_table.transit_gateway[each.key].id
}

###############################################################################
# VPC endpoint subnets
###############################################################################
resource "aws_subnet" "vpc_endpoint" {
  for_each = local.vpc_endpoint_subnet_map

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az_name

  tags = merge(var.tags, { Name = "${local.name}-vpce-${each.key}" })
}

resource "aws_route_table" "vpc_endpoint" {
  for_each = local.vpc_endpoint_subnet_map

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${local.name}-rtb-vpce-${each.key}" })
}

resource "aws_route_table_association" "vpc_endpoint" {
  for_each = local.vpc_endpoint_subnet_map

  subnet_id      = aws_subnet.vpc_endpoint[each.key].id
  route_table_id = aws_route_table.vpc_endpoint[each.key].id
}

resource "aws_route" "vpc_endpoint_tgw" {
  for_each = local.attach_transit_gateway && var.transit_gateway_default_route ? aws_route_table.vpc_endpoint : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.this]
}

###############################################################################
# State moves from the former "application" tier naming
###############################################################################
moved {
  from = aws_subnet.application
  to   = aws_subnet.private
}

moved {
  from = aws_route_table.application
  to   = aws_route_table.private
}

moved {
  from = aws_route_table_association.application
  to   = aws_route_table_association.private
}

moved {
  from = aws_route.application_tgw
  to   = aws_route.private_tgw
}
