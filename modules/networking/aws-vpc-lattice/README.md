# aws-vpc-lattice

Provisions an Amazon VPC Lattice **service network** (optional) and a set of
**services**, each with a target group, an HTTPS listener forwarding to it, and
an association to the service network. Optionally attaches an IAM auth policy
(from principal ARNs you supply), subscribes access logs to CloudWatch, and
creates CNAME records for each service's custom domain.

## Usage

```hcl
module "lattice" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/networking/aws-vpc-lattice?ref=v0.2.0"

  providers = { aws = aws.workload }

  project_name = "my-project"
  environment  = "dev"

  create_service_network    = true
  service_network_auth_type = "AWS_IAM"
  service_network_vpc_ids   = ["vpc-0123456789"]

  vpc_id = "vpc-0123456789"

  services = {
    payments = {
      auth_type          = "AWS_IAM"
      custom_domain_name = "orders.internal.my-project.example.com"
      certificate_arn    = "arn:aws:acm:ap-southeast-1:111122223333:certificate/abc"
      principals         = ["arn:aws:iam::111122223333:root"]
      target_group = {
        port = 8080
        health_check = {
          path = "/healthz"
        }
      }
    }
  }

  create_dns_records = true
  route53_zone_id    = "Z0123456789ABC"
}
```

Key outputs: `service_network_id`, `service_arns`, `service_dns_names`,
`target_group_arns`.

## Providers

This module uses the **default** `aws` provider. Redirect it per module block:
`providers = { aws = aws.workload }`.

## IAM

This module creates **no** `aws_iam_*` resources. Lattice auth policies
(`aws_vpclattice_auth_policy`) are generated only from the principal ARNs you
pass per service in `services[*].principals`. Cross-account DNS records (zone in
a different account) are handled outside the module.
