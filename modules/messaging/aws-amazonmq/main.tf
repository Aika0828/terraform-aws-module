locals {
  name = "${var.project_name}-${var.environment}"

  broker_security_group_ids = concat(
    var.create_security_group ? [aws_security_group.this[0].id] : [],
    var.security_group_ids,
  )
}

###############################################################################
# Security group (optional — modern rule resources)
###############################################################################
resource "aws_security_group" "this" {
  count       = var.create_security_group ? 1 : 0
  name        = "${local.name}-mq-sg"
  description = "Access to the ${local.name} Amazon MQ (RabbitMQ) broker"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${local.name}-mq-sg" })
}

# RabbitMQ: 5671 (AMQP over TLS) and 443 (management console / HTTPS API).
resource "aws_vpc_security_group_ingress_rule" "amqps_from_sg" {
  for_each                     = var.create_security_group ? toset(var.allowed_security_group_ids) : []
  security_group_id            = aws_security_group.this[0].id
  referenced_security_group_id = each.value
  from_port                    = 5671
  to_port                      = 5671
  ip_protocol                  = "tcp"
  description                  = "AMQPS from security group ${each.value}"
}

resource "aws_vpc_security_group_ingress_rule" "console_from_sg" {
  for_each                     = var.create_security_group ? toset(var.allowed_security_group_ids) : []
  security_group_id            = aws_security_group.this[0].id
  referenced_security_group_id = each.value
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Management console (HTTPS) from security group ${each.value}"
}

resource "aws_vpc_security_group_ingress_rule" "amqps_from_cidr" {
  for_each          = var.create_security_group ? toset(var.allowed_cidr_blocks) : []
  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = each.value
  from_port         = 5671
  to_port           = 5671
  ip_protocol       = "tcp"
  description       = "AMQPS from CIDR ${each.value}"
}

resource "aws_vpc_security_group_ingress_rule" "console_from_cidr" {
  for_each          = var.create_security_group ? toset(var.allowed_cidr_blocks) : []
  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Management console (HTTPS) from CIDR ${each.value}"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  count             = var.create_security_group ? 1 : 0
  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

###############################################################################
# Broker
###############################################################################
resource "aws_mq_broker" "this" {
  #checkov:skip=CKV_AWS_209:MQ broker CMK is consumer-supplied
  #checkov:skip=CKV_AWS_48:MQ broker logging is consumer-configurable
  broker_name                = "${local.name}-mq"
  engine_type                = "RabbitMQ"
  engine_version             = var.engine_version
  host_instance_type         = var.host_instance_type
  deployment_mode            = var.deployment_mode
  publicly_accessible        = var.publicly_accessible
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  subnet_ids      = var.subnet_ids
  security_groups = local.broker_security_group_ids

  user {
    username = var.admin_username
    password = var.admin_password
  }

  tags = merge(var.tags, { Name = "${local.name}-mq" })
}
