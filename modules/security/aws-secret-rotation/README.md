# aws-secret-rotation

Attaches a rotation Lambda to one or more Secrets Manager secrets: the function,
its log group, the Secrets Manager invoke permission (scoped per secret) and the
`aws_secretsmanager_secret_rotation` schedule. Creates **no IAM** — you supply
the Lambda's `role_arn`.

## Usage

```hcl
module "secret_rotation" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/security/aws-secret-rotation?ref=v0.2.0"

  providers = { aws = aws.workload }

  project_name = "my-project"
  environment  = "dev"

  role_arn   = var.rotation_role_arn      # an existing role ARN you provide
  source_dir = "${path.module}/rotation"  # your rotation handler

  secret_arns                       = [module.secrets.secret_arns["db"]]
  rotation_automatically_after_days = 30
}
```

Supply **exactly one** package source: `source_dir`, `source_file`, `filename`,
or `s3_bucket` + `s3_key`. Outputs: `function_arn`, `rotated_secret_ids`.
