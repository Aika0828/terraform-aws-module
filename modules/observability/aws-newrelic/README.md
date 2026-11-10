# aws-newrelic

Links an AWS account to New Relic for metric collection, following the ECV
module standard. The module provisions **no IAM**: it takes the ARN of the
assume role that New Relic uses, which the caller owns.

## Usage

```hcl
module "newrelic" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/observability/aws-newrelic?ref=v0.2.0"

  providers = {
    aws      = aws.workload
    newrelic = newrelic
  }

  project_name = "my-project"
  environment  = "dev"

  newrelic_account_id  = var.newrelic_account_id
  integration_role_arn = aws_iam_role.newrelic_integration.arn
}
```

## Providers

This module declares both `aws` and `newrelic` in `required_providers` but
**configures neither**:

- The **default** `aws` provider is redirected by the caller
  (`providers = { aws = aws.workload }`).
- The `newrelic` provider is configured entirely in the consuming root
  (`account_id`, `api_key`, `region`) and passed in. There is **no inline
  `provider "newrelic"` block** in this module.

Neither provider version is pinned in the module; the root pins them.

## IAM

This module creates **no IAM resources**. Create the role New Relic assumes
(trusting New Relic's AWS account with the external ID from your New Relic
integration setup, with the policies New Relic requires) in the caller, and
pass its ARN as `integration_role_arn`.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of the linked account name. |
| `environment` | string | — | dev / uat / prod. |
| `integration_role_arn` | string | — | ARN of the role New Relic assumes. |
| `newrelic_account_id` | string | `null` | New Relic account ID (else provider default). |
| `link_account_name` | string | `null` | Linked account display name; else derived. |
| `metric_collection_mode` | string | `PUSH` | `PUSH` or `PULL`. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `linked_account_id` | New Relic linked AWS account ID. |
| `linked_account_name` | Linked account display name. |

See [`outputs.tf`](./outputs.tf) for the full list.
