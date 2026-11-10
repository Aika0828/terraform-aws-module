# terraform-aws-modules

Reusable, standardized Terraform modules for our AWS infrastructure. One repo,
many modules, each consumed by a pinned git tag.

## Consuming a module

```hcl
module "aurora" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/database/aws-rds-aurora?ref=v0.1.0"

  providers = { aws = aws.workload }
  # ...inputs...
}
```

Then `terraform init`. Always pin `?ref=vX.Y.Z` — never a branch. See the
[consuming root example](../example-live) for the single-root + per-env tfvars
pattern (no `environments/dev` folders).

### Vendor only the modules you need

To pull a *local copy* of just some modules (offline/air-gapped use, or to vendor
them into a project), use [`scripts/fetch-modules.sh`](scripts/fetch-modules.sh) —
a shallow **sparse checkout** that downloads only the paths you ask for, not the
whole repo:

```bash
# copy the script into your project (or curl it), then:
TFMOD_REPO=git@gitlab.ecvmsp.com:ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git \
  ./fetch-modules.sh -t v0.1.0 aws-vpc aws-ecs-cluster database/aws-rds-aurora

# → vendored into ./vendor/terraform-aws-modules/<domain>/<name>, referenced as:
#   source = "./vendor/terraform-aws-modules/networking/aws-vpc"

./fetch-modules.sh --list          # list everything available at the ref
```

Modules can be named bare (`aws-vpc`) or as `domain/name` (`networking/aws-vpc`).

## Layout

```
modules/<domain>/aws-<resource>/   # the modules
  providers.tf variables.tf main.tf outputs.tf README.md
```

| Domain | Modules |
|--------|---------|
| networking | [aws-vpc](modules/networking/aws-vpc) · [aws-hub-spoke](modules/networking/aws-hub-spoke) · [aws-vpc-endpoints](modules/networking/aws-vpc-endpoints) · [aws-route53](modules/networking/aws-route53) · [aws-vpc-lattice](modules/networking/aws-vpc-lattice) |
| loadbalancer | [aws-alb](modules/loadbalancer/aws-alb) · [aws-nlb](modules/loadbalancer/aws-nlb) |
| compute | [aws-ecs-cluster](modules/compute/aws-ecs-cluster) · [aws-ecs-service](modules/compute/aws-ecs-service) · [aws-ec2-bastion](modules/compute/aws-ec2-bastion) |
| database | [aws-rds-aurora](modules/database/aws-rds-aurora) · [aws-rds-instance](modules/database/aws-rds-instance) · [aws-rds-proxy](modules/database/aws-rds-proxy) · [aws-rds-backup-lifecycle](modules/database/aws-rds-backup-lifecycle) · [aws-elasticache](modules/database/aws-elasticache) · [aws-opensearch](modules/database/aws-opensearch) · [aws-dynamodb](modules/database/aws-dynamodb) |
| messaging | [aws-amazonmq](modules/messaging/aws-amazonmq) |
| security | [aws-secrets-manager](modules/security/aws-secrets-manager) · [aws-ssm-parameter](modules/security/aws-ssm-parameter) · [aws-secret-rotation](modules/security/aws-secret-rotation) · [aws-cognito](modules/security/aws-cognito) |
| edge | [aws-api-gateway](modules/edge/aws-api-gateway) · [aws-cloudfront](modules/edge/aws-cloudfront) · [aws-acm](modules/edge/aws-acm) |
| serverless | [aws-lambda](modules/serverless/aws-lambda) · [aws-scheduled-lambda](modules/serverless/aws-scheduled-lambda) |
| storage | [aws-s3](modules/storage/aws-s3) |
| observability | [aws-cloudwatch](modules/observability/aws-cloudwatch) · [aws-newrelic](modules/observability/aws-newrelic) |
| bootstrap | [aws-tfstate-backend](modules/bootstrap/aws-tfstate-backend) |
| cicd | [aws-codepipeline](modules/cicd/aws-codepipeline) |
| patterns | [aws-ecs-app](modules/patterns/aws-ecs-app) — composite (ECR + ALB + ECS service) |

All 33 modules pass `terraform fmt`, `terraform validate`, and follow the standard below.

## The module standard

Every module must:

1. Live at `modules/<domain>/aws-<resource>/`.
2. Have `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `README.md`.
3. Declare `required_providers.aws` with **no** version pin (the root pins it) and
   **no** inline `provider` block. The module uses the **default** `aws` provider;
   the consumer redirects it with `providers = { aws = aws.workload }`.
4. Pin `required_version = ">= 1.9.0"`.
5. Type and describe every variable. Identity via `project_name` + `environment`.
6. Rely on the root's provider `default_tags` for the 3 standard tags
   (`Environment`, `map-migrated`, `TerraformManaged`); only `merge()` a `Name`
   and `var.tags` in the module.
7. Describe every output; mark secrets `sensitive`.
8. Hardcode no app/env-specific names — everything is a variable.
9. Pass `fmt`, `validate`, `tflint`, `checkov` in CI.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full checklist.

## Versioning

Semver git tags `vMAJOR.MINOR.PATCH`. A breaking change to a module's
inputs/outputs is a MAJOR bump. Consumers pin the tag they want and upgrade
deliberately.

## Local checks

```bash
terraform fmt -recursive
# each module validates on its own (default provider, no backend/providers needed)
( cd modules/database/aws-rds-aurora && terraform init -backend=false && terraform validate )
```
