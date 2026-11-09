# aws-ecs-service

A Fargate ECS service: task definition, the service, a CloudWatch log group and
a task security group. Cluster, IAM roles, container image and (optionally) a
load-balancer target group are passed in — this module does **not** create them
(it creates **no IAM**), so it composes cleanly with `aws-ecs-cluster` and
`aws-alb`. You supply the execution/task role ARNs.

## Usage

```hcl
module "ecs_service" {
  source = "git::https://gitlab.com/<group>/terraform-aws-modules.git//modules/compute/aws-ecs-service?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "fin-app"
  environment  = "dev"

  cluster_arn        = module.ecs_cluster.cluster_arn
  execution_role_arn = var.ecs_execution_role_arn # an existing role ARN you provide
  task_role_arn      = var.ecs_task_role_arn

  container_image = "${aws_ecr_repository.app.repository_url}:latest"
  container_port  = 8080
  task_cpu        = 512
  task_memory     = 1024

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.app_subnet_id_list
  ingress_security_group_ids = [module.alb.security_group_id]
  target_group_arn           = module.alb.target_group_arn

  environment_variables = {
    LOG_CHANNEL = "stderr"
    TZ          = "Asia/Manila"
  }
}
```

Omit `target_group_arn` for a service with no load balancer (e.g. a worker).
