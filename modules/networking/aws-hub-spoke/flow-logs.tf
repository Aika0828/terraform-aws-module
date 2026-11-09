# VPC Flow Logs -> CloudWatch Logs. The IAM role the flow-log service assumes is
# supplied by the caller (flow_log_role_arn); this module creates no IAM.
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/vpc/flowlogs/${local.name}"
  retention_in_days = var.flow_log_retention_days

  tags = merge(var.tags, { Name = "${local.name}-vpc-flow-logs" })
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id          = aws_vpc.this.id
  traffic_type    = "ALL"
  iam_role_arn    = var.flow_log_role_arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn

  tags = merge(var.tags, { Name = "${local.name}-vpc-flow-log" })

  lifecycle {
    precondition {
      condition     = var.flow_log_role_arn != null
      error_message = "flow_log_role_arn must be set when enable_flow_logs = true."
    }
  }
}
