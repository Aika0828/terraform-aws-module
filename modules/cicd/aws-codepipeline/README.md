# aws-codepipeline

A CodePipeline with caller-defined stages, an optional CodeBuild project and an
artifact bucket (created here, or supply an existing one). Source and build
service roles are **inputs** — this module creates no IAM.

CodeStarSourceConnection actions get `ConnectionArn` auto-injected and CodeBuild
actions get `ProjectName` auto-injected (when `codebuild` is set), so stage
definitions stay compact. Anything you set in an action's `configuration`
overrides the injected value.

## Usage

```hcl
module "pipeline" {
  source = "git::https://gitlab.ecvmsp.com/ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git//modules/cicd/aws-codepipeline?ref=v0.1.0"

  providers = { aws = aws.workload }

  project_name = "fin-app"
  environment  = "dev"

  codepipeline_role_arn = aws_iam_role.codepipeline.arn
  codebuild_role_arn    = aws_iam_role.codebuild.arn

  create_github_connection = true

  codebuild = {
    privileged_mode = true
    environment_variables = {
      ENVIRONMENT = { value = "dev" }
    }
  }

  stages = [
    {
      name = "Source"
      actions = [{
        name             = "Source"
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeStarSourceConnection"
        version          = "1"
        output_artifacts = ["source_output"]
        configuration    = { FullRepositoryId = "org/repo", BranchName = "main" }
      }]
    },
    {
      name = "Build"
      actions = [{
        name             = "Build"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        version          = "1"
        input_artifacts  = ["source_output"]
        output_artifacts = ["build_output"]
      }]
    },
  ]
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

## IAM

This module creates no IAM. Pass `codepipeline_role_arn` (required) and, when
using `codebuild`, `codebuild_role_arn`. A created `aws_codestarconnections_connection`
is not IAM; it starts PENDING and must be completed in the console once.

## Inputs (key)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_name` | string | — | First part of every resource name. |
| `environment` | string | — | dev / uat / prod. |
| `codepipeline_role_arn` | string | — | CodePipeline service role ARN. |
| `codebuild_role_arn` | string | `null` | CodeBuild service role ARN (needed with `codebuild`). |
| `stages` | list(object) | — | Pipeline stages and actions. |
| `codebuild` | object | `null` | Optional CodeBuild project. |
| `artifact_bucket_name` | string | `null` | Existing artifact bucket; null creates one. |
| `create_github_connection` | bool | `false` | Create a CodeStar GitHub connection. |
| `pipeline_type` | string | `V2` | V1 or V2. |

See [`variables.tf`](./variables.tf) for the full list.

## Outputs (key)

| Name | Description |
|------|-------------|
| `pipeline_name` | Pipeline name. |
| `artifact_bucket_name` | Artifact bucket name. |
| `codebuild_project_name` | CodeBuild project name (or null). |
| `github_connection_arn` | Connection ARN in use (or null). |

See [`outputs.tf`](./outputs.tf) for the full list.
