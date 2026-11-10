# Contributing a module

Copy an existing module (start from `modules/database/aws-rds-aurora`) and keep
to the standard. Checklist before opening an MR:

## Structure
- [ ] Path is `modules/<domain>/aws-<resource>/`.
- [ ] Files present: `providers.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `README.md`.
- [ ] Validates standalone: `terraform init -backend=false && terraform validate`.

## Providers
- [ ] `providers.tf` declares `required_version = ">= 1.9.0"`.
- [ ] `required_providers.aws` has `source = "hashicorp/aws"` and **no** version pin.
- [ ] No inline `provider "aws" {}` block in the module.
- [ ] Uses the **default** `aws` provider (no `provider = ...` lines on resources);
      the consumer redirects it with `providers = { aws = aws.workload }`.

## Inputs
- [ ] Every variable has a `type` and a `description`.
- [ ] Identity comes from `project_name` + `environment`.
- [ ] Sensible `validation {}` blocks where it prevents foot-guns.
- [ ] No hardcoded project/env-specific names — all parameterized.
- [ ] Creates **no** IAM roles or policies — any role the module needs is passed in
      as an ARN variable (e.g. `execution_role_arn`).

## Tags
- [ ] The module does **not** hardcode `Environment` / `map-migrated` / `TerraformManaged`
      (those come from the root's provider `default_tags`).
- [ ] Resources tag with `merge(var.tags, { Name = "..." })` only.

## Outputs
- [ ] Every output has a `description`.
- [ ] Secrets / passwords / secret ARNs are `sensitive = true`.

## Quality gates (CI runs these)
- [ ] `terraform fmt -check -recursive`
- [ ] `terraform validate` (each module dir)
- [ ] `tflint --recursive`
- [ ] `checkov -d modules`

## Release
- [ ] Update the module `README.md` inputs/outputs.
- [ ] Tag `vX.Y.Z` (MAJOR for any breaking input/output change).
