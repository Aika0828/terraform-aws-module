locals {
  name = "${var.project_name}-${var.environment}"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "${local.name}-vpc" })
}

###############################################################################
# Subnets
###############################################################################
resource "aws_subnet" "public" {
  for_each          = var.public_subnet_cidrs
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(var.tags, { Name = "${local.name}-public-${each.key}" })
}

resource "aws_subnet" "private" {
  for_each          = var.private_subnet_cidrs
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(var.tags, { Name = "${local.name}-private-${each.key}" })
}

resource "aws_subnet" "isolated" {
  for_each          = var.isolated_subnet_cidrs
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(var.tags, { Name = "${local.name}-isolated-${each.key}" })
}

###############################################################################
# Internet gateway + NAT
###############################################################################
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${local.name}-igw" })
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${local.name}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = values(aws_subnet.public)[0].id

  tags       = merge(var.tags, { Name = "${local.name}-nat" })
  depends_on = [aws_internet_gateway.this]
}

###############################################################################
# Route tables
###############################################################################
# Public -> internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${local.name}-rtb-public" })
}

resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private -> NAT gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${local.name}-rtb-private" })
}

resource "aws_route" "private_nat" {
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# Isolated -> no egress route by default (local only)
resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${local.name}-rtb-isolated" })
}

resource "aws_route_table_association" "isolated" {
  for_each       = aws_subnet.isolated
  subnet_id      = each.value.id
  route_table_id = aws_route_table.isolated.id
}

###############################################################################
# State moves from the former "app" tier naming
###############################################################################
moved {
  from = aws_subnet.app
  to   = aws_subnet.private
}

moved {
  from = aws_route_table.app
  to   = aws_route_table.private
}

moved {
  from = aws_route.app_nat
  to   = aws_route.private_nat
}

moved {
  from = aws_route_table_association.app
  to   = aws_route_table_association.private
}
