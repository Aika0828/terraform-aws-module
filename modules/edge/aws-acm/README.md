# aws-acm

Issues an ACM certificate with DNS (or email) validation, following the ECV
module standard. When a Route 53 hosted zone is supplied, the module also
creates the DNS validation records and waits for the certificate to be issued.

## Usage

```hcl
module "acm" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/edge/aws-acm?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "sample-app"
  environment  = "dev"

  domain_name               = "app.example.com"
  subject_alternative_names = ["www.app.example.com"]

  # Automate DNS validation in this hosted zone:
  zone_id = "Z0123456789ABCDEFGHIJ"
}
```

To issue the certificate without automatic validation (for example when the
zone lives in another account), omit `zone_id` and create the validation
records yourself from the `domain_validation_options` output.

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block:

```hcl
providers = { aws = aws.workload }
```

The AWS provider version is **not** pinned in the module; the root pins it.
The module only adds a `Name` tag and whatever you pass in `tags`; standard
tags come from the root's provider `default_tags`.

> For CloudFront, the certificate must be issued in `us-east-1`. Point the
> redirected provider at a `us-east-1` aliased provider in that case.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `domain_name` | string | — | Primary FQDN for the certificate. |
| `subject_alternative_names` | list(string) | `[]` | Additional SANs. |
| `validation_method` | string | `DNS` | `DNS` or `EMAIL`. |
| `zone_id` | string | `null` | Route 53 zone for automatic DNS validation. |
| `key_algorithm` | string | `null` | e.g. `RSA_2048`, `EC_prime256v1`. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `certificate_arn` | Issued certificate ARN (resolves after validation when automated). |
| `domain_validation_options` | Records needed to validate externally. |
| `status` | Certificate status. |

See [`outputs.tf`](./outputs.tf) for the full list.
