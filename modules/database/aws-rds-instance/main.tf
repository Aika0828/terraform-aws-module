locals {
  name = "${var.project_name}-${var.environment}"

  # Read the password from Secrets Manager only when RDS is not managing it.
  master_password = var.manage_master_user_password ? null : jsondecode(
    data.aws_secretsmanager_secret_version.master[0].secret_string
  )[var.master_password_secret_json_key]

  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name}-final"
}

data "aws_secretsmanager_secret_version" "master" {
  count     = var.manage_master_user_password ? 0 : 1
  secret_id = var.master_password_secret_arn
}

###############################################################################
# Networking
###############################################################################
resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-rds"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { Name = "${local.name}-rds" })
}

resource "aws_security_group" "this" {
  name        = "${local.name}-rds-sg"
  description = "Access to the ${local.name} RDS instance"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${local.name}-rds-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "from_sg" {
  for_each                     = toset(var.allowed_security_group_ids)
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value
  from_port                    = var.port
  to_port                      = var.port
  ip_protocol                  = "tcp"
  description                  = "DB access from security group ${each.value}"
}

resource "aws_vpc_security_group_ingress_rule" "from_cidr" {
  for_each          = toset(var.allowed_cidr_blocks)
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = each.value
  from_port         = var.port
  to_port           = var.port
  ip_protocol       = "tcp"
  description       = "DB access from CIDR ${each.value}"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

###############################################################################
# Instance
###############################################################################
resource "aws_db_instance" "this" {
  #checkov:skip=CKV_AWS_118:Enhanced monitoring needs a consumer-supplied monitoring role ARN (modules create no IAM)
  #checkov:skip=CKV_AWS_129:RDS log exports to CloudWatch are consumer-configurable
  #checkov:skip=CKV_AWS_161:RDS IAM auth is a consumer-enabled option
  #checkov:skip=CKV_AWS_354:Performance Insights CMK is consumer-supplied
  identifier = local.name

  engine                     = var.engine
  engine_version             = var.engine_version
  instance_class             = var.instance_class
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  port                       = var.port
  db_name                    = var.database_name

  username                    = var.master_username
  manage_master_user_password = var.manage_master_user_password ? true : null
  password                    = var.manage_master_user_password ? null : local.master_password

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id
  multi_az              = var.multi_az

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = var.publicly_accessible
  ca_cert_identifier     = var.ca_cert_identifier

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  copy_tags_to_snapshot   = var.copy_tags_to_snapshot
  monitoring_interval     = var.monitoring_interval

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  deletion_protection         = var.deletion_protection
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately
  skip_final_snapshot         = var.skip_final_snapshot
  final_snapshot_identifier   = local.final_snapshot_identifier

  tags = merge(var.tags, { Name = local.name })

  lifecycle {
    # RDS-managed or externally-rotated passwords must not trigger diffs.
    ignore_changes = [password]

    precondition {
      condition     = var.manage_master_user_password || var.master_password_secret_arn != null
      error_message = "When manage_master_user_password = false, master_password_secret_arn must be set."
    }
  }
}
