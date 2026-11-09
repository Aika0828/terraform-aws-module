# aws-hub-spoke

A spoke VPC for a hub-and-spoke (transit gateway) topology. It creates the VPC
with four subnet tiers — **application**, **database**, **transit-gateway** and
**vpc-endpoint** — each with its own per-AZ route tables, plus the workload-side
transit gateway attachment, interface/gateway VPC endpoints, and optional VPC
flow logs. Subnets are declared per availability zone, so you control exactly how
many AZs and how many subnets per tier you span.

## Usage

```hcl
module "spoke" {
  source = "git::https://gitlab.com/<group>/terraform-aws-modules.git//modules/networking/aws-hub-spoke?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "fin-app"
  environment  = "dev"
  vpc_cidr     = "10.20.0.0/16"

  availability_zones = [
    {
      name                         = "ap-southeast-1a"
      application_subnet_cidrs     = ["10.20.0.0/24"]
      database_subnet_cidrs        = ["10.20.10.0/24"]
      transit_gateway_subnet_cidrs = ["10.20.20.0/28"]
      vpc_endpoint_subnet_cidrs    = ["10.20.30.0/24"]
    },
    {
      name                         = "ap-southeast-1b"
      application_subnet_cidrs     = ["10.20.1.0/24"]
      database_subnet_cidrs        = ["10.20.11.0/24"]
      transit_gateway_subnet_cidrs = ["10.20.21.0/28"]
      vpc_endpoint_subnet_cidrs    = ["10.20.31.0/24"]
    },
  ]

  transit_gateway_id = "tgw-0123456789abcdef0"

  enable_flow_logs  = true
  flow_log_role_arn = "arn:aws:iam::111122223333:role/vpc-flow-logs-role"
}
```

Key outputs: `vpc_id`, `application_subnet_ids`, `database_subnet_ids`,
`first_application_subnet_per_az_ids`, `transit_gateway_attachment_id`,
`interface_endpoint_ids`.

## Providers

This module uses the **default** `aws` provider only. Point it at your workload
account by redirecting it in the module block: `providers = { aws = aws.workload }`.

> **Cross-account note:** this is the *spoke* (workload) side. The attachment is
> created here, but **accepting** the attachment and wiring the hub/network
> account's transit-gateway, firewall and public route tables happen in the
> network account under a separate provider, so they are intentionally **not**
> part of this module — add them in the network-account configuration.

## IAM

This module creates no IAM. For flow logs, pass the ARN of a pre-existing role
the `vpc-flow-logs.amazonaws.com` service can assume via `flow_log_role_arn`, and
set `enable_flow_logs = true`.
