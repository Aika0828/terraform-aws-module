# aws-nlb

A Network Load Balancer with its security group, a target group (IP type, for
Fargate) and one or more listeners. Internal by default. Each listener forwards
to the single target group; add a TLS listener for TLS termination at the NLB.

Ingress to the listeners is explicit — pass `ingress_cidr_blocks`,
`ingress_prefix_list_ids` and/or `ingress_security_group_ids`. One ingress rule
is created per (listener port, source) combination.

## Usage

```hcl
module "nlb" {
  source = "git::https://gitlab.com/<group>/terraform-aws-modules.git//modules/loadbalancer/aws-nlb?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "fin-app"
  environment  = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.app_subnet_id_list
  internal   = true

  ingress_cidr_blocks = ["10.0.0.0/16"]

  listeners = [
    { port = 80, protocol = "TCP" },
    { port = 443, protocol = "TLS", certificate_arn = "arn:aws:acm:...:certificate/..." },
  ]

  target_group = {
    port     = 8080
    protocol = "TCP"
    health_check = {
      protocol = "HTTP"
      path     = "/health"
      matcher  = "200"
    }
  }
}
```

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block:

```hcl
providers = { aws = aws.workload }
```

The AWS provider version is **not** pinned in the module; the root pins it. The
module only adds a `Name` tag and whatever you pass in `tags`; the standard tags
come from the root's provider `default_tags`.

Feed `target_group_arn` into your ECS service or autoscaling group, and
`security_group_id` into the backend's ingress rules.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `vpc_id` | string | — | VPC for the target group and SG. |
| `subnet_ids` | list(string) | — | Subnets the NLB attaches to. |
| `internal` | bool | `true` | Internal vs internet-facing. |
| `listeners` | list(object) | TCP:80 | Listeners; each forwards to the TG. |
| `target_group` | object | — | Target group config (port, protocol, health_check). |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `nlb_dns_name` | DNS name of the NLB. |
| `target_group_arn` | Target group ARN. |
| `security_group_id` | NLB security group ID. |
| `listener_arns` | Listener ARNs. |

See [`outputs.tf`](./outputs.tf) for the full list.
