# aws-route53

Manages a Route 53 hosted zone and its records. It can **optionally create** a
public or private hosted zone (`create_zone`), or write records into an existing
zone (`create_zone = false` + `zone_id`). Records are a typed map and support
both simple records (A/CNAME/TXT…) and alias records (ALB, VPC Lattice, etc.).

## Usage

### Private zone + records

```hcl
module "dns" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/networking/aws-route53?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "fin-app"
  environment  = "dev"

  create_zone = true
  zone = {
    name    = "internal.fin-app.example.com"
    private = true
    vpc_ids = ["vpc-0123456789"]
  }

  records = {
    api = {
      name    = "api.internal.fin-app.example.com"
      type    = "CNAME"
      ttl     = 300
      records = ["abcd1234.vpc-lattice-svcs.ap-southeast-1.on.aws"]
    }
    alb = {
      name = "app.internal.fin-app.example.com"
      type = "A"
      alias = {
        name                   = "dualstack.my-alb-123.ap-southeast-1.elb.amazonaws.com"
        zone_id                = "Z1LMS91P8CMLE5"
        evaluate_target_health = true
      }
    }
  }
}
```

### Records only (existing zone)

```hcl
module "dns_records" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/networking/aws-route53?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "fin-app"
  environment  = "dev"

  create_zone = false
  zone_id     = "Z0123456789ABC"

  records = {
    web = { name = "www.example.com", type = "CNAME", records = ["example.com"] }
  }
}
```

Key outputs: `zone_id`, `name_servers`, `record_fqdns`.

## Providers

This module uses the **default** `aws` provider. Redirect it per module block:
`providers = { aws = aws.workload }`. Cross-account VPC-association authorization
(where a private zone lives in a different account from the VPC) is handled
outside this module.
