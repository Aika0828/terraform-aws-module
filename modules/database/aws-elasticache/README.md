# aws-elasticache

Provisions an Amazon ElastiCache for Redis replication group with its subnet
group and security group, encrypted at rest and in transit by default,
following the ECV module standard.

## Usage

```hcl
module "redis" {
  source = "git::https://gitlab.com/<group>/terraform-aws-modules.git//modules/database/aws-elasticache?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "sample-app"
  environment  = "dev"

  vpc_id                     = "vpc-0123456789"
  subnet_ids                 = ["subnet-aaa", "subnet-bbb"]
  allowed_security_group_ids = ["sg-app"]

  node_type          = "cache.t4g.small"
  engine_version     = "7.1"
  num_cache_clusters = 2
}
```

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block (`providers = { aws = aws.workload }`).
The AWS provider version is **not** pinned in the module; the root pins it. The
standard tags come from the root's provider `default_tags`; the module only adds
a `Name` tag and whatever you pass in `tags`.

Setting `num_cache_clusters > 1` enables automatic failover and Multi-AZ.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `vpc_id` | string | — | VPC for the security group. |
| `subnet_ids` | list(string) | — | Subnets for the cache subnet group. |
| `allowed_security_group_ids` | list(string) | `[]` | SGs allowed on the cache port. |
| `node_type` | string | `cache.t4g.small` | Node instance type. |
| `engine_version` | string | `7.1` | Redis engine version. |
| `num_cache_clusters` | number | `1` | Nodes; > 1 enables failover + Multi-AZ. |
| `auth_token` | string | `null` | Redis AUTH token (requires transit encryption). |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `primary_endpoint_address` | Primary (write) endpoint. |
| `reader_endpoint_address` | Reader (read-only) endpoint. |
| `port` | Redis port. |
| `security_group_id` | Replication group security group ID. |
| `arn` | Replication group ARN. |

See [`outputs.tf`](./outputs.tf) for the full list.
