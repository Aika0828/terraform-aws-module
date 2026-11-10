# aws-ssm-parameter

Creates one or more AWS Systems Manager (SSM) parameters from a typed map,
following the ECV module standard. Supports `String`, `SecureString`, and
`StringList` types; `SecureString` values are marked sensitive.

## Usage

```hcl
module "ssm_parameters" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/security/aws-ssm-parameter?ref=v0.2.0"

  providers = { aws = aws.workload }

  project_name = "my-project"
  environment  = "dev"
  path_prefix  = "/my-project/dev"

  parameters = {
    api_base_url = {
      name        = "api-base-url"
      type        = "String"
      value       = "https://api.example.com"
      description = "Upstream API base URL"
    }

    api_token = {
      name        = "api-token"
      type        = "SecureString"
      value       = var.api_token
      description = "Encrypted API token"
    }
  }

  tags = { CostCenter = "payments" }
}
```

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block:

```hcl
providers = { aws = aws.workload }
```

The AWS provider version is **not** pinned in the module; the root pins it. The
standard account tags come from the root's provider `default_tags`; the module
only adds a `Name` tag and whatever you pass in `tags`.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every parameter name. |
| `environment` | string | — | dev / uat / prod. |
| `path_prefix` | string | `null` | Optional leading path for parameter names. |
| `parameters` | map(object) | `{}` | Parameters to create (see `variables.tf`). |
| `tags` | map(string) | `{}` | Extra tags merged onto every parameter. |

Each `parameters` entry supports `name`, `type`, `value`, `description`, `tier`,
and `key_id`.

## Outputs

| Name | Description |
|------|-------------|
| `parameter_arns` | Map of key to parameter ARN. |
| `parameter_names` | Map of key to parameter name. |
| `parameter_versions` | Map of key to current version. |
