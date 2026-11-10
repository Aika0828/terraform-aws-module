# aws-rds-aurora

Provisions an Amazon Aurora cluster (writer + optional readers) with its subnet
group and security group, following the ECV module standard.

## Usage

```hcl
module "aurora" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/database/aws-rds-aurora?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "sample-app"
  environment  = "dev"

  vpc_id                     = "vpc-0123456789"
  subnet_ids                 = ["subnet-aaa", "subnet-bbb"]
  allowed_security_group_ids = ["sg-app"]

  database_name  = "finapp"
  instance_class = "db.t4g.medium"
  instance_count = 1

  deletion_protection = false
  skip_final_snapshot = true
}
```

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block:

```hcl
providers = { aws = aws.workload }
```

The AWS provider version is **not** pinned in the module; the root pins it.
The three standard tags (`Environment`, `map-migrated`, `TerraformManaged`) come
from the root's provider `default_tags`. The module only adds a `Name` tag and
whatever you pass in `tags`.

## Credentials

By default (`manage_master_user_password = true`) RDS creates and rotates the
master password in Secrets Manager; its ARN is exposed as
`master_user_secret_arn`. To supply your own secret instead, set
`manage_master_user_password = false` and point `master_password_secret_arn` at a
Secrets Manager secret whose JSON contains the `master_password_secret_json_key`.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `vpc_id` | string | — | VPC for the security group. |
| `subnet_ids` | list(string) | — | ≥ 2 subnets in different AZs. |
| `allowed_security_group_ids` | list(string) | `[]` | SGs allowed on the DB port. |
| `database_name` | string | — | Initial database name. |
| `engine` | string | `aurora-postgresql` | `aurora-postgresql` or `aurora-mysql`. |
| `instance_class` | string | `db.r6g.large` | Per-instance class. |
| `instance_count` | number | `2` | 1 writer + (n-1) readers. |
| `manage_master_user_password` | bool | `true` | RDS-managed master secret. |
| `deletion_protection` | bool | `true` | Block deletion. |
| `skip_final_snapshot` | bool | `false` | Skip final snapshot on destroy. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `endpoint` | Writer endpoint. |
| `reader_endpoint` | Reader endpoint. |
| `port` | DB port. |
| `master_user_secret_arn` | RDS-managed secret ARN (sensitive). |
| `security_group_id` | Cluster security group ID. |
| `cluster_arn` | Cluster ARN. |

See [`outputs.tf`](./outputs.tf) for the full list.
