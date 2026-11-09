# aws-s3

Provisions a general-purpose S3 bucket with sensible, secure defaults:
versioning on, server-side encryption, all public access blocked, and optional
lifecycle rules and bucket policy. Follows the ECV module standard.

## Usage

```hcl
module "assets" {
  source = "git::https://gitlab.com/<group>/terraform-aws-modules.git//modules/storage/aws-s3?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name  = "sample-app"
  environment   = "dev"
  bucket_suffix = "assets"

  versioning_enabled = true

  encryption = {
    sse_algorithm = "aws:kms"
    kms_key_id    = var.kms_key_arn
  }

  lifecycle_rules = [
    {
      id              = "expire-old-versions"
      noncurrent_version_expiration_days = 90
      transitions = [
        { days = 30, storage_class = "STANDARD_IA" },
      ]
    },
  ]
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

## Security defaults

- **Public access**: all four block settings default to `true`.
- **Encryption**: SSE-S3 (`AES256`) by default; set `encryption.sse_algorithm`
  to `aws:kms` with a `kms_key_id` for a CMK.
- **Versioning**: enabled by default.
- **Bucket policy**: pass a rendered JSON string via `bucket_policy`. This
  module creates **no IAM resources**.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of the bucket name. |
| `environment` | string | — | dev / uat / prod. |
| `bucket_name` | string | `null` | Explicit name; else derived. |
| `bucket_suffix` | string | `bucket` | Suffix when name is derived. |
| `versioning_enabled` | bool | `true` | Object versioning. |
| `encryption` | object | SSE-S3 | SSE algorithm / KMS key. |
| `block_public_access` | object | all true | Public access block. |
| `lifecycle_rules` | list(object) | `[]` | Expiration / transitions. |
| `bucket_policy` | string | `null` | Policy JSON string. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `bucket_id` | Bucket name. |
| `bucket_arn` | Bucket ARN. |
| `bucket_regional_domain_name` | For CloudFront origins. |

See [`outputs.tf`](./outputs.tf) for the full list.
