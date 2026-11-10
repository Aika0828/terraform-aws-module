# aws-api-gateway

Provisions an API Gateway v2 (HTTP) API with an auto-deployed stage, Lambda
proxy integrations and routes, and an optional Lambda (REQUEST) authorizer,
following the ECV module standard.

## Usage

```hcl
module "api" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/edge/aws-api-gateway?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "sample-app"
  environment  = "dev"

  authorizer = {
    authorizer_uri = module.authorizer_lambda.invoke_arn
  }

  routes = [
    {
      route_key          = "GET /api/transactions"
      integration_uri    = module.transactions_lambda.invoke_arn
      authorization_type = "CUSTOM"
    },
    {
      route_key       = "POST /api/health"
      integration_uri = module.health_lambda.invoke_arn
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

## IAM

This module creates **no IAM resources**. Grant API Gateway permission to
invoke your integration and authorizer Lambdas from the caller, using the
`execution_arn` output (e.g. with `aws_lambda_permission`).

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `protocol_type` | string | `HTTP` | `HTTP` or `WEBSOCKET`. |
| `stage_name` | string | `null` | Stage name; defaults to `environment`. |
| `routes` | list(object) | `[]` | route_key → integration_uri (+ auth). |
| `authorizer` | object | `null` | Optional Lambda REQUEST authorizer (ARN only). |
| `cors_configuration` | object | `null` | Optional CORS for an HTTP API. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `api_id` | API ID. |
| `api_endpoint` | Default endpoint URL. |
| `execution_arn` | For granting Lambda invoke permission. |
| `stage_invoke_url` | Invoke URL of the deployed stage. |

See [`outputs.tf`](./outputs.tf) for the full list.
