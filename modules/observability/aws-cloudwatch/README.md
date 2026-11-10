# aws-cloudwatch

Provisions a CloudWatch dashboard and/or a set of metric alarms, parameterized,
following the ECV module standard. Both parts are optional: supply a
`dashboard_body` to create a dashboard, and/or a list of `alarms`.

## Usage

```hcl
module "monitoring" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/observability/aws-cloudwatch?ref=v0.2.0"

  providers = { aws = aws.workload }

  project_name = "my-project"
  environment  = "dev"

  # Dashboard from a JSON template:
  dashboard_body = templatefile("${path.module}/dashboard.json.tpl", {
    environment = "dev"
  })

  # Metric alarms:
  alarms = [
    {
      alarm_name          = "alb-5xx"
      namespace           = "AWS/ApplicationELB"
      metric_name         = "HTTPCode_ELB_5XX_Count"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 5
      period              = 300
      evaluation_periods  = 1
      statistic           = "Sum"
      dimensions          = { LoadBalancer = module.alb.arn_suffix }
      alarm_actions       = [var.sns_topic_arn]
    },
  ]
}
```

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block:

```hcl
providers = { aws = aws.workload }
```

The AWS provider version is **not** pinned in the module; the root pins it.
The module only adds a `Name` tag and whatever you pass in `tags`; standard
tags come from the root's provider `default_tags`.

## Notes

- `dashboard_body` is a JSON string; build it with `templatefile` or
  `jsonencode`. CloudWatch dashboards do not support tags.
- `alarm_actions` / `ok_actions` take existing SNS topic (or other) ARNs. This
  module creates **no IAM or SNS resources**.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `dashboard_name` | string | `null` | Dashboard name; else derived. |
| `dashboard_body` | string | `null` | Dashboard JSON; null skips the dashboard. |
| `alarms` | list(object) | `[]` | Metric alarms to create. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `dashboard_arn` | Dashboard ARN (or null). |
| `alarm_arns` | Map of alarm name → ARN. |

See [`outputs.tf`](./outputs.tf) for the full list.
