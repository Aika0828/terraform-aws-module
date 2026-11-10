# aws-vpc

A VPC with three subnet tiers — **public** (internet-facing, via IGW), **app**
(private, egress via a NAT gateway) and **isolated** (no internet route, for
databases) — plus the internet gateway, NAT gateway and route tables.

Subnets are defined per availability zone as `{ az = cidr }` maps, so you control
exactly how many AZs you span.

## Usage

```hcl
module "vpc" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/networking/aws-vpc?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "fin-app"
  environment  = "dev"
  vpc_cidr     = "10.0.0.0/16"

  public_subnet_cidrs   = { "ap-southeast-1a" = "10.0.0.0/24", "ap-southeast-1b" = "10.0.1.0/24" }
  app_subnet_cidrs      = { "ap-southeast-1a" = "10.0.10.0/24", "ap-southeast-1b" = "10.0.11.0/24" }
  isolated_subnet_cidrs = { "ap-southeast-1a" = "10.0.20.0/24", "ap-southeast-1b" = "10.0.21.0/24" }
}
```

Key outputs: `vpc_id`, `app_subnet_ids` / `app_subnet_id_list`, `isolated_subnet_id_list`, `nat_gateway_id`.

> **Note:** the **isolated** tier has no default route (truly isolated). If a
> workload there needs outbound internet, put it in the **app** tier instead.
