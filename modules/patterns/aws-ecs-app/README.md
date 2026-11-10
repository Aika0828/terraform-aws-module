# aws-ecs-app (composite)

An opinionated web-app stack that wires the primitives together: an **ECR repo**,
an optional **ALB** (`aws-alb`) and an **ECS service** (`aws-ecs-service`),
connected to each other. It creates **no cluster and no IAM** — pass in the
`cluster_arn` (from `aws-ecs-cluster`) and the execution/task role ARNs.

## Usage

```hcl
module "web" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/patterns/aws-ecs-app?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "fin-app"
  environment  = "dev"

  vpc_id         = module.vpc.vpc_id
  app_subnet_ids = module.vpc.app_subnet_id_list
  cluster_arn    = module.ecs_cluster.cluster_arn

  execution_role_arn = var.ecs_execution_role_arn
  task_role_arn      = var.ecs_task_role_arn

  container_port = 8080
  image_tag      = "1.4.0"

  alb_ingress_cidr_blocks = ["10.0.0.0/16"]

  environment_variables = {
    LOG_CHANNEL = "stderr"
    TZ          = "Asia/Manila"
  }
}
```

Push your image to `module.web.ecr_repository_url`. Set `create_alb = false` for
a worker service with no load balancer. Key outputs: `ecr_repository_url`,
`alb_dns_name`, `service_name`.
