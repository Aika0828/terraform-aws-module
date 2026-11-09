# Workload-side attachment of this VPC to the shared transit gateway.
# Acceptance and hub/network-account route-table wiring are performed outside
# this module (they live in the network account, under a different provider).
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count = local.attach_transit_gateway ? 1 : 0

  vpc_id             = aws_vpc.this.id
  subnet_ids         = [for s in aws_subnet.transit_gateway : s.id]
  transit_gateway_id = var.transit_gateway_id

  # These toggles have no effect on a shared transit gateway, but are set to
  # make the intended (centralised) routing explicit.
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = merge(var.tags, { Name = "${local.name}-tgw-attachment" })
}
