# aws-tfstate-backend

The classic Terraform remote-state backend: a versioned, encrypted S3 bucket
with public access fully blocked and a lifecycle rule that expires old state
versions, plus a DynamoDB lock table (`LockID` hash key, PAY_PER_REQUEST).

This module creates **no IAM resources**. Grant access to the bucket and table
through policies you own.

## Usage

```hcl
module "tfstate_backend" {
  source = "git::https://gitlab.com/<group>/terraform-aws-modules.git//modules/bootstrap/aws-tfstate-backend?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "fin-app"
  environment  = "dev"
}
```

Then point the backend at the created resources:

```hcl
terraform {
  backend "s3" {
    bucket         = "fin-app-dev-tfstate"
    key            = "infra/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "fin-app-dev-tfstate-lock"
    encrypt        = true
  }
}
```

Bootstrap note: create this backend with local state first, then migrate state
into the bucket it created.

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
| `dynamodb_table_name` | string | `null` | Lock table; null derives `<project>-<env>-tfstate-lock`. |
| `kms_key_arn` | string | `null` | KMS key for SSE; null uses AES256. |
| `noncurrent_version_expiration_days` | number | `90` | Expire old state versions. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `bucket_name` | State bucket name. |
| `dynamodb_table_name` | Lock table name. |
| `bucket_arn` | State bucket ARN. |

See [`outputs.tf`](./outputs.tf) for the full list.
