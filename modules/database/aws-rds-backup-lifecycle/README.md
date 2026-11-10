# aws-rds-backup-lifecycle

A scheduled Lambda that manages manual RDS snapshots: it takes a daily snapshot
and expires snapshots past a retention window (always keeping the most recent
one). Includes two EventBridge schedules, an optional SNS topic, and a
CloudWatch alarm on Lambda failures. Follows the ECV module standard.

## Usage

```hcl
module "rds_backup_lifecycle" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/database/aws-rds-backup-lifecycle?ref=v0.2.0"

  providers = { aws = aws.workload }

  project_name = "my-project"
  environment  = "dev"

  # The execution role is created OUTSIDE this module (NO-IAM rule). It must
  # allow rds:DescribeDBInstances/DescribeDBSnapshots/CreateDBSnapshot/
  # DeleteDBSnapshot/AddTagsToResource/ListTagsForResource and CloudWatch Logs.
  lambda_role_arn = "arn:aws:iam::111122223333:role/rds-backup-lifecycle-role"

  db_instance_identifier = "my-project-dev-db"
  retention_days         = 7
  create_schedule_cron   = "0 18 * * ? *"
  cleanup_schedule_cron  = "30 18 * * ? *"

  create_sns_topic       = true
  alert_recipient_emails = ["ops@example.com"]
}
```

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block:

```hcl
providers = { aws = aws.workload }
```

The AWS provider version is **not** pinned in the module; the root pins it. The
module also uses the `hashicorp/archive` provider to package the Lambda. The
standard tags come from the root's provider `default_tags`; the module adds a
`Name` tag and whatever you pass in `tags`.

## IAM

Per the module standard, this module creates **no** IAM resources. Create the
Lambda execution role in the root module and pass its ARN as `lambda_role_arn`.
The role must allow, at minimum:

- `rds:DescribeDBInstances`, `rds:DescribeDBSnapshots`
- `rds:CreateDBSnapshot`, `rds:DeleteDBSnapshot`
- `rds:AddTagsToResource`, `rds:ListTagsForResource`
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`

## Lambda source

The Python handler lives at [`src/rds_backup_lifecycle.py`](./src/rds_backup_lifecycle.py)
and is rendered with `templatefile()` (the target identifier, snapshot prefix,
managed tag, and retention days are injected at package time) and zipped via the
`archive_file` data source. The snapshot-create and cleanup actions are
dispatched from a single function on the EventBridge target `input`.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `lambda_role_arn` | string | — | Execution role ARN (created externally). |
| `db_instance_identifier` | string | — | RDS instance to snapshot. |
| `retention_days` | number | `7` | Days before a snapshot is expired. |
| `create_schedule_cron` | string | `0 18 * * ? *` | Cron for snapshot creation. |
| `cleanup_schedule_cron` | string | `30 18 * * ? *` | Cron for snapshot cleanup. |
| `create_sns_topic` | bool | `true` | Create SNS topic + failure alarm. |
| `alert_recipient_emails` | list(string) | `[]` | Failure-alert subscribers. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `lambda_function_arn` | Snapshot-lifecycle Lambda ARN. |
| `snapshot_prefix` | Identifier prefix on managed snapshots. |
| `sns_topic_arn` | Failure-alert SNS topic ARN (null if disabled). |

See [`outputs.tf`](./outputs.tf) for the full list.
