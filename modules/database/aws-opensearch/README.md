# aws-opensearch

Provisions an Amazon OpenSearch Service domain inside a VPC with its own
security group, node-to-node and at-rest encryption, enforced HTTPS, fine-grained
access control, and optional slow-search logging, following the ECV module
standard.

## Usage

```hcl
module "opensearch" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/database/aws-opensearch?ref=v0.2.0"

  providers = { aws = aws.workload }

  project_name = "my-project"
  environment  = "dev"

  vpc_id                     = "vpc-0123456789"
  subnet_ids                 = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
  allowed_security_group_ids = ["sg-0123456789abcdef0"]

  instance_type  = "t3.medium.search"
  instance_count = 3

  master_username            = "admin"
  master_password_secret_arn = "arn:aws:secretsmanager:...:secret:opensearch"
}
```

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block (`providers = { aws = aws.workload }`).
The AWS provider version is **not** pinned in the module; the root pins it. The
standard tags come from the root's provider `default_tags`; the module only adds
a `Name` tag and whatever you pass in `tags`.

## Credentials

The master password for fine-grained access control is read from Secrets Manager:
point `master_password_secret_arn` at a secret whose JSON contains the
`master_password_secret_json_key` (default `opensearch_password`). The module
creates no IAM resources; the domain access policy defaults to allowing `es:*`
scoped to the domain, with network access restricted by the VPC and security
group. Override it with `access_policies` (a JSON string) if required.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `vpc_id` | string | — | VPC for the security group. |
| `subnet_ids` | list(string) | — | One subnet per AZ. |
| `allowed_security_group_ids` | list(string) | `[]` | SGs allowed on HTTPS. |
| `instance_type` | string | `t3.medium.search` | Data node instance type. |
| `instance_count` | number | `3` | Number of data nodes. |
| `engine_version` | string | `OpenSearch_2.9` | Engine version. |
| `master_password_secret_arn` | string | — | Secret holding the master password. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `endpoint` | Domain HTTPS endpoint. |
| `dashboard_endpoint` | OpenSearch Dashboards endpoint. |
| `domain_arn` | Domain ARN. |
| `security_group_id` | Domain security group ID. |

See [`outputs.tf`](./outputs.tf) for the full list.
