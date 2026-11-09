locals {
  name              = "${var.project_name}-${var.environment}"
  link_account_name = var.link_account_name != null ? var.link_account_name : "${local.name}-aws-integration"
}

# Links an AWS account to New Relic using a role the caller owns.
# This module creates no IAM resources; the assume role ARN is supplied as input.
resource "newrelic_cloud_aws_link_account" "this" {
  account_id             = var.newrelic_account_id
  arn                    = var.integration_role_arn
  name                   = local.link_account_name
  metric_collection_mode = var.metric_collection_mode
}
