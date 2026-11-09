locals {
  name = "${var.project_name}-${var.environment}"

  # Read the password from Secrets Manager only when RDS is not managing it.
  master_password = var.manage_master_user_password ? null : jsondecode(
    data.aws_secretsmanager_secret_version.master[0].secret_string
  )[var.master_password_secret_json_key]

  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name}-aurora-final"
}

data "aws_secretsmanager_secret_version" "master" {
  count     = var.manage_master_user_password ? 0 : 1
  secret_id = var.master_password_secret_arn
}

###############################################################################
# Networking
###############################################################################
resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-aurora"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { Name = "${local.name}-aurora" })
}

resource "aws_security_group" "this" {
  name        = "${local.name}-aurora-sg"
  description = "Access to the ${local.name} Aurora cluster"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${local.name}-aurora-sg" })
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
# Cluster
###############################################################################
resource "aws_rds_cluster" "this" {
  cluster_identifier = "${local.name}-aurora"
  engine             = var.engine
  engine_version     = var.engine_version
  engine_mode        = "provisioned"

  database_name = var.database_name
  port          = var.port

  master_username             = var.master_username
  manage_master_user_password = var.manage_master_user_password ? true : null
  master_password             = var.manage_master_user_password ? null : local.master_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  storage_encrypted       = var.storage_encrypted
  kms_key_id              = var.kms_key_id
  deletion_protection     = var.deletion_protection
  apply_immediately       = var.apply_immediately

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = local.final_snapshot_identifier

  tags = merge(var.tags, { Name = "${local.name}-aurora" })

  lifecycle {
    # RDS-managed or externally-rotated passwords must not trigger diffs.
    ignore_changes = [master_password]

    precondition {
      condition     = var.manage_master_user_password || var.master_password_secret_arn != null
      error_message = "When manage_master_user_password = false, master_password_secret_arn must be set."
    }
  }
}

resource "aws_rds_cluster_instance" "this" {
  count              = var.instance_count
  identifier         = "${local.name}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  db_subnet_group_name         = aws_db_subnet_group.this.name
  performance_insights_enabled = var.performance_insights_enabled

  tags = merge(var.tags, { Name = "${local.name}-aurora-${count.index}" })
}
