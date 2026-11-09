locals {
  name = "${var.project_name}-${var.environment}"
  # ALB and target-group names are capped at 32 chars.
  alb_name = substr("${local.name}-alb", 0, 32)
  tg_name  = substr("${local.name}-tg", 0, 32)
}

resource "aws_security_group" "this" {
  name        = "${local.name}-alb-sg"
  description = "Ingress to the ${local.name} load balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${local.name}-alb-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "cidr" {
  for_each          = toset(var.ingress_cidr_blocks)
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = each.value
  from_port         = var.listener_port
  to_port           = var.listener_port
  ip_protocol       = "tcp"
  description       = "Listener access from CIDR ${each.value}"
}

resource "aws_vpc_security_group_ingress_rule" "prefix_list" {
  for_each          = toset(var.ingress_prefix_list_ids)
  security_group_id = aws_security_group.this.id
  prefix_list_id    = each.value
  from_port         = var.listener_port
  to_port           = var.listener_port
  ip_protocol       = "tcp"
  description       = "Listener access from prefix list ${each.value}"
}

resource "aws_vpc_security_group_ingress_rule" "sg" {
  for_each                     = toset(var.ingress_security_group_ids)
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value
  from_port                    = var.listener_port
  to_port                      = var.listener_port
  ip_protocol                  = "tcp"
  description                  = "Listener access from security group ${each.value}"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

resource "aws_lb" "this" {
  name               = local.alb_name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = var.subnet_ids

  tags = merge(var.tags, { Name = local.alb_name })
}

resource "aws_lb_target_group" "this" {
  name                 = local.tg_name
  port                 = var.target_group.port
  protocol             = var.target_group.protocol
  vpc_id               = var.vpc_id
  target_type          = var.target_group.target_type
  deregistration_delay = var.target_group.deregistration_delay

  health_check {
    path                = var.target_group.health_check.path
    protocol            = var.target_group.health_check.protocol
    matcher             = var.target_group.health_check.matcher
    interval            = var.target_group.health_check.interval
    timeout             = var.target_group.health_check.timeout
    healthy_threshold   = var.target_group.health_check.healthy_threshold
    unhealthy_threshold = var.target_group.health_check.unhealthy_threshold
  }

  tags = merge(var.tags, { Name = local.tg_name })
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  certificate_arn   = var.listener_protocol == "HTTPS" ? var.certificate_arn : null
  ssl_policy        = var.listener_protocol == "HTTPS" ? var.ssl_policy : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = merge(var.tags, { Name = "${local.name}-listener" })
}
