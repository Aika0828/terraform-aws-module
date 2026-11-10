# aws-ec2-bastion

An EC2 bastion host and its security group. IMDSv2 is enforced and the root
volume is encrypted. By default the instance has no public IP and no SSH ingress
— attach an SSM instance profile and reach it through Session Manager.

This module creates **no IAM resources**. To enable SSM Session Manager, create
the instance profile in the root (or another module) and pass its name as
`iam_instance_profile`.

## Usage

```hcl
module "bastion" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/compute/aws-ec2-bastion?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "fin-app"
  environment  = "dev"

  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnet_id_list[0]

  # Latest Amazon Linux 2023 is resolved from SSM when ami_id is omitted.
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.bastion_ssm.name

  # Optional direct SSH:
  # allowed_ssh_cidr_blocks = ["10.0.0.0/16"]
  # key_name                = "my-key"
}
```

## Providers

This module uses the **default** `aws` provider. Point it at your workload
account by redirecting it in the module block:

```hcl
providers = { aws = aws.workload }
```

The AWS provider version is **not** pinned in the module; the root pins it. The
module only adds a `Name` tag and whatever you pass in `tags`; the standard tags
come from the root's provider `default_tags`.

## AMI selection

Leave `ami_id` null to resolve the latest Amazon Linux 2023 AMI from the SSM
public parameter in `ami_ssm_parameter_name` (x86_64 by default). For arm64
instance types, point `ami_ssm_parameter_name` at the `...-arm64` parameter.
Pass `ami_id` to pin a specific AMI.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `vpc_id` | string | — | VPC for the security group. |
| `subnet_id` | string | — | Subnet to launch in. |
| `instance_type` | string | `t3.micro` | Instance type. |
| `ami_id` | string | `null` | AMI; null resolves AL2023 from SSM. |
| `iam_instance_profile` | string | `null` | Existing instance profile name (no IAM is created). |
| `allowed_ssh_cidr_blocks` | list(string) | `[]` | CIDRs allowed on port 22. |
| `allowed_ssh_security_group_ids` | list(string) | `[]` | SGs allowed on port 22. |
| `associate_public_ip` | bool | `false` | Attach a public IP. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `instance_id` | Bastion instance ID. |
| `private_ip` | Private IP. |
| `security_group_id` | Bastion security group ID. |

See [`outputs.tf`](./outputs.tf) for the full list.
