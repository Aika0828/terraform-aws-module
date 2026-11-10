# aws-ecs-service

A Fargate ECS service: task definition, the service, a CloudWatch log group and
a task security group. Cluster, IAM roles, container image and (optionally) a
load-balancer target group are passed in — this module does **not** create them
(it creates **no IAM**), so it composes cleanly with `aws-ecs-cluster` and
`aws-alb`. You supply the execution/task role ARNs.

## Usage

```hcl
module "ecs_service" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/compute/aws-ecs-service?ref=v0.2.0"

  providers = { aws = aws.workload }

  project_name = "my-project"
  environment  = "dev"

  cluster_arn        = module.ecs_cluster.cluster_arn
  execution_role_arn = var.ecs_execution_role_arn # an existing role ARN you provide
  task_role_arn      = var.ecs_task_role_arn

  container_name  = var.service.container_name
  container_image = var.service.container_image # e.g. <account>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>
  container_port  = var.service.container_port
  task_cpu        = var.service.task_cpu
  task_memory     = var.service.task_memory

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_id_list
  ingress_security_group_ids = [module.alb.security_group_id]
  target_group_arn           = module.alb.target_group_arn

  environment_variables = var.service.environment_variables
}
```

Omit `target_group_arn` for a service with no load balancer (e.g. a worker).
