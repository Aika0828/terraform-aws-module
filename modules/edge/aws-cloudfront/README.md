# aws-cloudfront

Provisions a CloudFront distribution, optionally fronting a **VPC origin**
(for example an internal Application Load Balancer), following the ECV module
standard.

## Usage

```hcl
module "cloudfront" {
  source = "git::https://gitlab.com/<group>/terraform-aws-modules.git//modules/edge/aws-cloudfront?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "sample-app"
  environment  = "dev"

  aliases         = ["app.example.com"]
  certificate_arn = module.acm.certificate_arn # must be in us-east-1

  vpc_origin = {
    arn         = module.alb.arn
    domain_name = module.alb.dns_name
    origin_id   = "alb-origin"
  }

  default_cache_behavior = {
    target_origin_id         = "alb-origin"
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # Managed-AllViewer
  }
}
```

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block:

```hcl
providers = { aws = aws.workload }
```

The AWS provider version is **not** pinned in the module; the root pins it.
The module only adds a `Name` tag and whatever you pass in `tags`; standard
tags come from the root's provider `default_tags`.

## Notes

- `certificate_arn` must reference an ACM certificate in **us-east-1**.
- Use `vpc_origin` for an internal ALB/NLB origin; use `origins` for S3 or
  public custom HTTP origins. `default_cache_behavior.target_origin_id` must
  match one of their `origin_id`s.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `aliases` | list(string) | `[]` | Alternate domain names (CNAMEs). |
| `certificate_arn` | string | `null` | ACM cert ARN (us-east-1). |
| `vpc_origin` | object | `null` | Creates a VPC origin from an ALB/NLB ARN. |
| `origins` | list(object) | `[]` | Additional S3 / custom origins. |
| `default_cache_behavior` | object | — | Default behavior (target origin, methods, policies). |
| `price_class` | string | `PriceClass_100` | CloudFront price class. |
| `web_acl_id` | string | `null` | WAF web ACL to associate. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `distribution_id` | Distribution ID. |
| `domain_name` | `*.cloudfront.net` domain name. |
| `hosted_zone_id` | Zone ID for Route 53 alias records. |
| `vpc_origin_id` | Created VPC origin ID (or null). |

See [`outputs.tf`](./outputs.tf) for the full list.
