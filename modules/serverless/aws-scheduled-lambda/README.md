# aws-scheduled-lambda

A generic AWS Lambda function invoked on an EventBridge schedule, following the
ECV module standard. It creates the function, its CloudWatch log group, the
EventBridge rule/target/permission, and — optionally — an SNS topic plus a
CloudWatch alarm on invocation errors. It creates **no** IAM; pass in an existing
execution role via `role_arn`.

## Usage

```hcl
module "scheduled_lambda" {
  source = "git::https://gitlab.com/<group>/terraform-aws-modules.git//modules/serverless/aws-scheduled-lambda?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name  = "sample-app"
  environment   = "dev"
  function_name = "nightly-cleanup"

  role_arn = aws_iam_role.lambda_exec.arn # created in the root, not here

  runtime    = "python3.13"
  handler    = "cleanup.lambda_handler"
  source_dir = "${path.module}/src/cleanup"
  timeout    = 120

  schedule_expression = "cron(0 1 * * ? *)"
  event_input         = jsonencode({ action = "cleanup" })

  environment_variables = {
    TABLE_NAME = "sessions"
  }

  log_retention_days = 90

  # Optional failure alerting
  enable_error_alarm        = true
  alarm_subscription_emails = ["ops@example.com"]

  tags = { CostCenter = "payments" }
}
```

## Providers

This module uses the **default** `aws` provider (and the `archive` provider to
build packages from source). Point AWS at your workload account by redirecting it
in the module block:

```hcl
providers = { aws = aws.workload }
```

Neither provider version is pinned in the module; the root pins them. The
standard account tags come from the root's provider `default_tags`; the module
only adds a `Name` tag and whatever you pass in `tags`.

## IAM

This module creates no IAM resources. Create the execution role (and its policy
attachments for logging, VPC ENIs, and any downstream services) in the root
module and pass its ARN as `role_arn`.

## Package source

Provide exactly one of `source_dir`, `source_file`, `filename`, or
`s3_bucket` + `s3_key` (+ optional `s3_object_version`).

## Failure alerting

Set `enable_error_alarm = true` to create an SNS topic (encrypted with
`sns_kms_master_key_id`), subscribe `alarm_subscription_emails`, and raise a
CloudWatch alarm on the function's `Errors` metric. When disabled, none of these
resources are created and the related outputs are `null`.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `function_name` | string | — | Logical function name. |
| `role_arn` | string | — | Execution role ARN (created elsewhere). |
| `runtime` | string | — | e.g. `python3.13`. |
| `handler` | string | — | e.g. `index.handler`. |
| `schedule_expression` | string | — | `rate(...)` or `cron(...)`. |
| `event_input` | string | `null` | Constant JSON payload per invocation. |
| `vpc_config` | object | `null` | Subnets + security groups. |
| `log_retention_days` | number | `90` | Log group retention. |
| `enable_error_alarm` | bool | `false` | Create SNS topic + error alarm. |
| `alarm_subscription_emails` | list(string) | `[]` | Alert email subscriptions. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs

| Name | Description |
|------|-------------|
| `function_arn` | Function ARN. |
| `function_name` | Function name. |
| `event_rule_arn` | EventBridge rule ARN. |
| `log_group_name` | Log group name. |
| `sns_topic_arn` | Failure-alert SNS topic ARN (null when disabled). |
| `error_alarm_arn` | Error alarm ARN (null when disabled). |
