locals {
  name = "${var.project_name}-${var.environment}"
  ami  = coalesce(var.ami_id, try(data.aws_ssm_parameter.ami[0].value, null))
}

# Resolve the latest Amazon Linux 2023 AMI when no ami_id is supplied.
data "aws_ssm_parameter" "ami" {
  count = var.ami_id == null ? 1 : 0
  name  = var.ami_ssm_parameter_name
}

###############################################################################
# Security group
###############################################################################
resource "aws_security_group" "this" {
  name        = "${local.name}-bastion-sg"
  description = "Access to the ${local.name} bastion host"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${local.name}-bastion-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "ssh_cidr" {
  for_each          = toset(var.allowed_ssh_cidr_blocks)
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = each.value
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "SSH access from CIDR ${each.value}"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_sg" {
  for_each                     = toset(var.allowed_ssh_security_group_ids)
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  description                  = "SSH access from security group ${each.value}"
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
resource "aws_instance" "this" {
  ami                         = local.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = var.iam_instance_profile
  key_name                    = var.key_name
  user_data                   = var.user_data
  associate_public_ip_address = var.associate_public_ip
  monitoring                  = var.monitoring
  ebs_optimized               = var.ebs_optimized

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    encrypted   = true
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  tags = merge(var.tags, { Name = "${local.name}-bastion" })
}
