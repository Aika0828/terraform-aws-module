# aws-ecs-cluster

An ECS cluster with Container Insights and Fargate capacity providers.

## Usage

```hcl
module "ecs_cluster" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/compute/aws-ecs-cluster?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "fin-app"
  environment  = "dev"
}
```

Outputs: `cluster_id`, `cluster_arn`, `cluster_name` — feed these into
`aws-ecs-service`.
