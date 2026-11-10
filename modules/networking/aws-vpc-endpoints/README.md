# aws-vpc-endpoints

A generic module for creating **interface** and **gateway** VPC endpoints from
typed maps. Interface endpoints can share a managed security group created by the
module, or bring their own. Gateway endpoints (S3, DynamoDB) are associated with
the route tables you pass.

## Usage

```hcl
module "endpoints" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/networking/aws-vpc-endpoints?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "fin-app"
  environment  = "dev"

  vpc_id             = "vpc-0123456789"
  default_subnet_ids = ["subnet-aaa", "subnet-bbb"]

  create_security_group        = true
  security_group_ingress_cidrs = ["10.20.0.0/16"]

  interface_endpoints = {
    ecr_api        = { service_name = "com.amazonaws.ap-southeast-1.ecr.api" }
    ecr_dkr        = { service_name = "com.amazonaws.ap-southeast-1.ecr.dkr" }
    ssm            = { service_name = "com.amazonaws.ap-southeast-1.ssm" }
    secretsmanager = { service_name = "com.amazonaws.ap-southeast-1.secretsmanager" }
  }

  gateway_endpoints = {
    s3 = {
      service_name    = "com.amazonaws.ap-southeast-1.s3"
      route_table_ids = ["rtb-aaa", "rtb-bbb"]
    }
  }
}
```

Each interface endpoint may override `subnet_ids`, `security_group_ids` and
`private_dns_enabled`; unset values fall back to `default_subnet_ids` and the
managed security group.

Key outputs: `interface_endpoint_ids`, `gateway_endpoint_ids`,
`interface_endpoint_dns_entries`, `security_group_id`.

## Providers

This module uses the **default** `aws` provider. Redirect it per module block:
`providers = { aws = aws.workload }`.
