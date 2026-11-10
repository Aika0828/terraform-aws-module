# aws-lambda

A generic AWS Lambda function module, following the ECV module standard. It
creates the function and its CloudWatch log group; it **does not** create any
IAM. Pass in an existing execution role via `role_arn`.

The deployment package can come from a zipped source directory or file, a
pre-built `.zip`, or an object already in S3.

## Usage

```hcl
module "lambda" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/serverless/aws-lambda?ref=v0.2.0"

  providers = { aws = aws.workload }

  project_name  = "my-project"
  environment   = "dev"
  function_name = "processor"

  role_arn = aws_iam_role.lambda_exec.arn # created in the root, not here

  runtime     = "python3.13"
  handler     = "index.handler"
  source_dir  = "${path.module}/src/processor"
  memory_size = 256
  timeout     = 60

  environment_variables = {
    TABLE_NAME = "orders"
  }

  vpc_config = {
    subnet_ids         = ["subnet-aaa", "subnet-bbb"]
    security_group_ids = ["sg-lambda"]
  }

  log_retention_days = 30

  tags = { CostCenter = "payments" }
}
```

## Providers

This module uses the **default** `aws` provider (and the `archive` provider to
build packages from source). Point AWS at your workload account by redirecting it
in the module block:

```hcl
providers = { aws = aws.workload }
```

Neither provider version is pinned in the module; the root pins them. The
standard account tags come from the root's provider `default_tags`; the module
only adds a `Name` tag and whatever you pass in `tags`.

## IAM

This module creates no IAM resources. Create the execution role (and its policy
attachments for logging, VPC ENIs, and any downstream services) in the root
module and pass its ARN as `role_arn`.

## Package source

Provide exactly one of:

- `source_dir` — a directory zipped at plan time (uses the `archive` provider).
- `source_file` — a single file zipped at plan time.
- `filename` — a path to a pre-built `.zip`.
- `s3_bucket` + `s3_key` (+ optional `s3_object_version`) — an object in S3.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `function_name` | string | — | Logical function name. |
| `role_arn` | string | — | Execution role ARN (created elsewhere). |
| `runtime` | string | — | e.g. `python3.13`. |
| `handler` | string | — | e.g. `index.handler`. |
| `memory_size` | number | `128` | Memory in MB. |
| `timeout` | number | `30` | Timeout in seconds. |
| `environment_variables` | map(string) | `{}` | Env vars. |
| `layers` | list(string) | `[]` | Layer version ARNs. |
| `vpc_config` | object | `null` | Subnets + security groups. |
| `log_retention_days` | number | `90` | Log group retention. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs

| Name | Description |
|------|-------------|
| `function_arn` | Function ARN. |
| `function_name` | Function name. |
| `invoke_arn` | Invoke ARN. |
| `log_group_name` | Log group name. |
| `log_group_arn` | Log group ARN. |
