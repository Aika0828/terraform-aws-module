# aws-alb

An Application Load Balancer with its security group, a target group (IP type,
for Fargate) and a listener. Internal by default.

Ingress to the listener is explicit — pass `ingress_cidr_blocks`,
`ingress_prefix_list_ids` (e.g. the CloudFront origin-facing prefix list) and/or
`ingress_security_group_ids`.

## Usage

```hcl
module "alb" {
  source = "git::https://gitlab.com/<group>/terraform-aws-modules.git//modules/loadbalancer/aws-alb?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "fin-app"
  environment  = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.app_subnet_id_list

  ingress_cidr_blocks = ["10.0.0.0/16"]

  target_group = {
    port = 8080
    health_check = { path = "/health" }
  }
}
```

Feed `target_group_arn` into `aws-ecs-service`, and `security_group_id` into the
service's `ingress_security_group_ids`.
