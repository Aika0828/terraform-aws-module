# aws-amazonmq

Provisions an Amazon MQ for RabbitMQ broker with its (optional) security group,
following the ECV module standard.

## Usage

```hcl
module "rabbitmq" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/messaging/aws-amazonmq?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "sample-app"
  environment  = "dev"

  vpc_id                     = "vpc-0123456789"
  subnet_ids                 = ["subnet-aaa", "subnet-bbb"]
  allowed_security_group_ids = ["sg-app"]

  host_instance_type = "mq.m7g.medium"
  deployment_mode    = "CLUSTER_MULTI_AZ"

  admin_username = "app_mq_user"
  admin_password = var.rabbitmq_admin_password # sensitive; sourced from Secrets Manager / TF vars
}
```

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block:

```hcl
providers = { aws = aws.workload }
```

The AWS provider version is **not** pinned in the module; the root pins it. The
standard tags come from the root's provider `default_tags`; the module adds a
`Name` tag and whatever you pass in `tags`.

## Credentials

`admin_username` / `admin_password` set the broker's administrative user. The
password variable and the `admin_password` output are both marked **sensitive**.
Source the password from Secrets Manager (or a TF var) in the root module rather
than hardcoding it.

## Security group

By default (`create_security_group = true`) the module creates a security group
in `vpc_id` and opens the AMQPS port (`5671`) and the management console port
(`443`) to `allowed_security_group_ids` and `allowed_cidr_blocks`. Set
`create_security_group = false` and pass `security_group_ids` to attach your own.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `subnet_ids` | list(string) | — | Broker subnets (2 for CLUSTER_MULTI_AZ). |
| `engine_version` | string | `4.2` | RabbitMQ engine version. |
| `host_instance_type` | string | `mq.m7g.medium` | Broker host type. |
| `deployment_mode` | string | `CLUSTER_MULTI_AZ` | `SINGLE_INSTANCE` or `CLUSTER_MULTI_AZ`. |
| `admin_username` | string | — | Admin RabbitMQ username. |
| `admin_password` | string (sensitive) | — | Admin RabbitMQ password (≥ 12 chars). |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `broker_arn` | Broker ARN. |
| `amqps_endpoints` | AMQPS endpoints (port 5671). |
| `console_urls` | Management console URLs. |
| `admin_password` | Admin password (sensitive). |
| `security_group_id` | Broker security group ID (null if not created). |

See [`outputs.tf`](./outputs.tf) for the full list.
