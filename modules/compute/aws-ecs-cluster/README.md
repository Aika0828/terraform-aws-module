# aws-ecs-cluster

A generic ECS cluster. By default it creates only the cluster (Container Insights
on) and associates the `FARGATE` / `FARGATE_SPOT` capacity providers with a
`FARGATE` default strategy. Everything else — name, Insights level, ECS Exec
logging, Service Connect namespace, capacity providers and strategy — is set by
the consumer, typically from their `tfvars`.

It creates no services, task definitions, ECR repositories, load balancers or
IAM. Use `aws-ecs-service` (and `aws-alb` / `aws-nlb`) for workloads.

## Usage

```hcl
module "ecs_cluster" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/compute/aws-ecs-cluster?ref=v0.2.0"

  providers = { aws = aws.workload }

  project_name = var.project_name
  environment  = var.environment

  name                               = var.ecs_cluster.name
  container_insights                 = var.ecs_cluster.container_insights
  capacity_providers                 = var.ecs_cluster.capacity_providers
  default_capacity_provider_strategy = var.ecs_cluster.default_capacity_provider_strategy
  execute_command_configuration      = var.ecs_cluster.execute_command_configuration
  service_connect_namespace_arn      = var.ecs_cluster.service_connect_namespace_arn
}
```

Example `terraform.tfvars`:

```hcl
project_name = "my-project"
environment  = "dev"

ecs_cluster = {
  name               = null # -> my-project-dev-cluster
  container_insights = "enabled"
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = [
    { capacity_provider = "FARGATE", weight = 1, base = 1 },
    { capacity_provider = "FARGATE_SPOT", weight = 3 },
  ]
  execute_command_configuration = {
    logging = "OVERRIDE"
    log_configuration = {
      cloud_watch_log_group_name = "/ecs/exec/my-project-dev"
    }
  }
  service_connect_namespace_arn = null
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `project_name` | string | — | First part of the default cluster name. |
| `environment` | string | — | Lowercase alphanumeric environment. |
| `name` | string | `null` | Cluster name override. |
| `container_insights` | string | `"enabled"` | `enhanced`, `enabled` or `disabled`. |
| `execute_command_configuration` | object | `null` | ECS Exec KMS key and logging. |
| `service_connect_namespace_arn` | string | `null` | Service Connect default namespace. |
| `capacity_providers` | list(string) | `["FARGATE", "FARGATE_SPOT"]` | Empty list skips the association. |
| `default_capacity_provider_strategy` | list(object) | `[{ FARGATE, weight 1 }]` | Default strategy. |
| `tags` | map(string) | `{}` | Extra tags. |

## Outputs

`cluster_id`, `cluster_arn`, `cluster_name` — feed these into `aws-ecs-service`.
