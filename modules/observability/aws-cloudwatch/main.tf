locals {
  name           = "${var.project_name}-${var.environment}"
  dashboard_name = var.dashboard_name != null ? var.dashboard_name : "${local.name}-dashboard"

  alarms = { for a in var.alarms : a.alarm_name => a }
}

resource "aws_cloudwatch_dashboard" "this" {
  count = var.dashboard_body != null ? 1 : 0

  dashboard_name = local.dashboard_name
  dashboard_body = var.dashboard_body
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.alarms

  alarm_name          = "${local.name}-${each.value.alarm_name}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description
  dimensions          = each.value.dimensions
  treat_missing_data  = each.value.treat_missing_data
  datapoints_to_alarm = each.value.datapoints_to_alarm
  alarm_actions       = each.value.alarm_actions
  ok_actions          = each.value.ok_actions

  tags = merge(var.tags, { Name = "${local.name}-${each.value.alarm_name}" })
}
