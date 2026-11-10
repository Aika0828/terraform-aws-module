locals {
  name = "${var.project_name}-${var.environment}"

  # Expand each AZ's per-tier CIDR lists into flat, keyed maps so every subnet
  # gets a stable resource address ("<az>-<index>").
  private_subnet_map = merge([
    for az in var.availability_zones : {
      for idx, cidr in az.private_subnet_cidrs :
      "${az.name}-${idx}" => { az_name = az.name, cidr = cidr, index = idx }
    }
  ]...)

  database_subnet_map = merge([
    for az in var.availability_zones : {
      for idx, cidr in az.database_subnet_cidrs :
      "${az.name}-${idx}" => { az_name = az.name, cidr = cidr, index = idx }
    }
  ]...)

  transit_gateway_subnet_map = merge([
    for az in var.availability_zones : {
      for idx, cidr in az.transit_gateway_subnet_cidrs :
      "${az.name}-${idx}" => { az_name = az.name, cidr = cidr, index = idx }
    }
  ]...)

  vpc_endpoint_subnet_map = merge([
    for az in var.availability_zones : {
      for idx, cidr in az.vpc_endpoint_subnet_cidrs :
      "${az.name}-${idx}" => { az_name = az.name, cidr = cidr, index = idx }
    }
  ]...)

  attach_transit_gateway = var.transit_gateway_id != ""
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "${local.name}-vpc" })
}
