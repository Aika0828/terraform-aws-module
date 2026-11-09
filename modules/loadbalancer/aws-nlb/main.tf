locals {
  name = "${var.project_name}-${var.environment}"
  # NLB and target-group names are capped at 32 chars.
  nlb_name = substr("${local.name}-nlb", 0, 32)
  tg_name  = substr("${local.name}-tg", 0, 32)

  listener_ports = distinct([for l in var.listeners : l.port])

  # One ingress rule per (listener port, source) combination.
  ingress_cidr_rules = {
    for pair in setproduct(local.listener_ports, var.ingress_cidr_blocks) :
    "${pair[0]}-${pair[1]}" => { port = pair[0], cidr = pair[1] }
  }
  ingress_prefix_rules = {
    for pair in setproduct(local.listener_ports, var.ingress_prefix_list_ids) :
    "${pair[0]}-${pair[1]}" => { port = pair[0], prefix_list_id = pair[1] }
  }
  ingress_sg_rules = {
    for pair in setproduct(local.listener_ports, var.ingress_security_group_ids) :
    "${pair[0]}-${pair[1]}" => { port = pair[0], sg = pair[1] }
  }
}

###############################################################################
# Security group
###############################################################################
resource "aws_security_group" "this" {
  name        = "${local.name}-nlb-sg"
  description = "Ingress to the ${local.name} network load balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${local.name}-nlb-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "cidr" {
  for_each          = local.ingress_cidr_rules
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
  description       = "Listener ${each.value.port} access from CIDR ${each.value.cidr}"
}

resource "aws_vpc_security_group_ingress_rule" "prefix_list" {
  for_each          = local.ingress_prefix_rules
  security_group_id = aws_security_group.this.id
  prefix_list_id    = each.value.prefix_list_id
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
  description       = "Listener ${each.value.port} access from prefix list ${each.value.prefix_list_id}"
}

resource "aws_vpc_security_group_ingress_rule" "sg" {
  for_each                     = local.ingress_sg_rules
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value.sg
  from_port                    = each.value.port
  to_port                      = each.value.port
  ip_protocol                  = "tcp"
  description                  = "Listener ${each.value.port} access from security group ${each.value.sg}"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

###############################################################################
# Load balancer
###############################################################################
resource "aws_lb" "this" {
  name                             = local.nlb_name
  internal                         = var.internal
  load_balancer_type               = "network"
  security_groups                  = [aws_security_group.this.id]
  subnets                          = var.subnet_ids
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  tags = merge(var.tags, { Name = local.nlb_name })
}

resource "aws_lb_target_group" "this" {
  name                 = local.tg_name
  port                 = var.target_group.port
  protocol             = var.target_group.protocol
  vpc_id               = var.vpc_id
  target_type          = var.target_group.target_type
  deregistration_delay = var.target_group.deregistration_delay
  preserve_client_ip   = var.target_group.preserve_client_ip

  dynamic "health_check" {
    for_each = var.target_group.health_check == null ? [] : [var.target_group.health_check]
    content {
      protocol            = health_check.value.protocol
      port                = health_check.value.port
      path                = health_check.value.path
      matcher             = health_check.value.matcher
      interval            = health_check.value.interval
      timeout             = health_check.value.timeout
      healthy_threshold   = health_check.value.healthy_threshold
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }

  tags = merge(var.tags, { Name = local.tg_name })
}

resource "aws_lb_listener" "this" {
  count = length(var.listeners)

  load_balancer_arn = aws_lb.this.arn
  port              = var.listeners[count.index].port
  protocol          = var.listeners[count.index].protocol
  certificate_arn   = var.listeners[count.index].protocol == "TLS" ? var.listeners[count.index].certificate_arn : null
  ssl_policy        = var.listeners[count.index].protocol == "TLS" ? var.listeners[count.index].ssl_policy : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = merge(var.tags, { Name = "${local.name}-listener-${var.listeners[count.index].port}" })
}
