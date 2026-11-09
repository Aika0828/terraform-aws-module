# aws-rds-proxy

Provisions an Amazon RDS Proxy in front of an RDS/Aurora cluster or instance,
with its default target group, target registration, and (optionally) a security
group, following the ECV module standard.

## Usage

```hcl
module "rds_proxy" {
  source = "git::https://gitlab.com/<group>/terraform-aws-modules.git//modules/database/aws-rds-proxy?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "sample-app"
  environment  = "dev"

  vpc_id                     = "vpc-0123456789"
  vpc_subnet_ids             = ["subnet-aaa", "subnet-bbb"]
  allowed_security_group_ids = ["sg-app"]

  engine_family = "POSTGRESQL"
  port          = 5432

  # The role and secret are created OUTSIDE this module (NO-IAM rule).
  role_arn    = "arn:aws:iam::111122223333:role/rds-proxy-secrets-role"
  secret_arns = ["arn:aws:secretsmanager:ap-southeast-1:111122223333:secret:rds-creds-abc123"]

  # Register exactly one target:
  db_cluster_identifier = "sample-app-dev-aurora"
}
```

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block:

```hcl
providers = { aws = aws.workload }
```

The AWS provider version is **not** pinned in the module; the root pins it.
The standard tags come from the root's provider `default_tags`. The module only
adds a `Name` tag and whatever you pass in `tags`.

## IAM

Per the module standard, this module creates **no** IAM resources. An RDS Proxy
needs a role that can read the database credentials from Secrets Manager; create
that role (and the secret) in the root module and pass them in as `role_arn` and
`secret_arns`.

## Security group

By default (`create_security_group = true`) the module creates a security group
in `vpc_id` and opens the DB `port` to `allowed_security_group_ids` and
`allowed_cidr_blocks`. Set `create_security_group = false` and pass
`vpc_security_group_ids` to attach your own.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `vpc_subnet_ids` | list(string) | — | ≥ 2 subnets in different AZs. |
| `engine_family` | string | `POSTGRESQL` | `POSTGRESQL`, `MYSQL`, or `SQLSERVER`. |
| `role_arn` | string | — | Role the proxy assumes to read the secret. |
| `secret_arns` | list(string) | — | Secrets Manager ARN(s) of the DB credentials. |
| `db_cluster_identifier` | string | `null` | Target cluster (set this OR instance). |
| `db_instance_identifier` | string | `null` | Target instance (set this OR cluster). |
| `require_tls` | bool | `true` | Require TLS client connections. |
| `debug_logging` | bool | `false` | Log full SQL (debugging only). |
| `idle_client_timeout` | number | `1800` | Idle client timeout, seconds. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `endpoint` | Proxy endpoint to connect to in place of the DB. |
| `proxy_arn` | Proxy ARN. |
| `security_group_id` | Proxy security group ID (null if not created). |
| `default_target_group_arn` | Default target group ARN. |

See [`outputs.tf`](./outputs.tf) for the full list.
