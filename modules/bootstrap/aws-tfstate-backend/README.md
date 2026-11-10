# aws-tfstate-backend

A Terraform remote-state backend: a versioned, encrypted S3 bucket with public
access fully blocked and a lifecycle rule that expires old state versions.

State **locking** uses the S3 backend's native lock file (`use_lockfile = true`,
Terraform ≥ 1.10) — **no DynamoDB table is required**.

This module creates **no IAM resources**. Grant access to the bucket through
policies you own.

## Usage

```hcl
module "tfstate_backend" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/bootstrap/aws-tfstate-backend?ref=v0.2.0"

  providers = { aws = aws.workload }

  project_name = "my-project"
  environment  = "dev"
}
```

Then point the backend at the created resources:

```hcl
terraform {
  backend "s3" {
    bucket       = "my-project-dev-tfstate"
    key          = "infra/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true # native S3 state locking (Terraform >= 1.10)
    encrypt      = true
  }
}
```

Bootstrap note: create this backend with local state first, then migrate state
into the bucket it created.

### Migrating from a DynamoDB lock table

If you previously used `dynamodb_table`, you can set both `dynamodb_table` and
`use_lockfile = true` during a transition (Terraform writes/checks both), then
remove `dynamodb_table` and delete the old table once every root has migrated.

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block:

```hcl
providers = { aws = aws.workload }
```

The AWS provider version is **not** pinned in the module; the root pins it. The
module only adds a `Name` tag and whatever you pass in `tags`; the standard tags
come from the root's provider `default_tags`.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `bucket_name` | string | `null` | State bucket; null derives `<project>-<env>-tfstate`. |
| `kms_key_arn` | string | `null` | KMS key for SSE; null uses AES256. |
| `noncurrent_version_expiration_days` | number | `90` | Expire old state versions. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `bucket_name` | State bucket name. |
| `bucket_arn` | State bucket ARN. |
| `bucket_region` | State bucket region. |

See [`outputs.tf`](./outputs.tf) for the full list.
