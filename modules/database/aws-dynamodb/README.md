# aws-dynamodb

Provisions a generic Amazon DynamoDB table with configurable keys, attributes,
global secondary indexes, TTL, point-in-time recovery, and server-side
encryption, following the ECV module standard.

## Usage

```hcl
module "dynamodb" {
  source = "git::https://gitlab.com/<group>/terraform-aws-modules.git//modules/database/aws-dynamodb?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "sample-app"
  environment  = "dev"

  table_name = "cauth-tokens"
  hash_key   = "sub"
  range_key  = "aud"

  attributes = [
    { name = "sub", type = "S" },
    { name = "aud", type = "S" },
  ]

  global_secondary_indexes = [
    {
      name            = "aud-index"
      hash_key        = "aud"
      projection_type = "ALL"
    },
  ]

  ttl = {
    attribute_name = "expires_at"
    enabled        = true
  }
}
```

The full table name is `"<project_name>-<environment>-<table_name>"`, e.g.
`sample-app-dev-cauth-tokens`.

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block (`providers = { aws = aws.workload }`).
The AWS provider version is **not** pinned in the module; the root pins it. The
standard tags come from the root's provider `default_tags`; the module only adds
a `Name` tag and whatever you pass in `tags`.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of the table name. |
| `environment` | string | — | dev / uat / prod. |
| `table_name` | string | — | Table suffix. |
| `hash_key` | string | — | Partition key attribute. |
| `range_key` | string | `null` | Sort key attribute. |
| `billing_mode` | string | `PAY_PER_REQUEST` | `PAY_PER_REQUEST` or `PROVISIONED`. |
| `attributes` | list(object) | — | Attribute definitions (`name`, `type` S/N/B). |
| `global_secondary_indexes` | list(object) | `[]` | GSI definitions. |
| `ttl` | object | `null` | TTL config. |
| `point_in_time_recovery_enabled` | bool | `true` | Continuous backups. |
| `server_side_encryption` | object | `{}` | Encryption config. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `table_name` | Table name. |
| `table_arn` | Table ARN. |
| `stream_arn` | Stream ARN (null when disabled). |

See [`outputs.tf`](./outputs.tf) for the full list.
