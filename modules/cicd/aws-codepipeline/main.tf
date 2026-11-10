locals {
  name = "${var.project_name}-${var.environment}"

  create_artifact_bucket = var.artifact_bucket_name == null
  artifact_bucket        = local.create_artifact_bucket ? aws_s3_bucket.artifacts[0].bucket : var.artifact_bucket_name

  connection_arn = var.create_github_connection ? aws_codestarconnections_connection.github[0].arn : var.github_connection_arn

  # Values auto-merged into stage action configuration by provider type, so
  # callers need not repeat the connection ARN or CodeBuild project name.
  action_default_configuration = merge(
    local.connection_arn == null ? {} : {
      CodeStarSourceConnection = { ConnectionArn = local.connection_arn }
    },
    var.codebuild == null ? {} : {
      CodeBuild = { ProjectName = aws_codebuild_project.this[0].name }
    },
  )
}

###############################################################################
# Artifact bucket (created only when no existing bucket is supplied)
###############################################################################
resource "aws_s3_bucket" "artifacts" {
  count         = local.create_artifact_bucket ? 1 : 0
  bucket        = "${local.name}-pipeline-artifacts"
  force_destroy = var.artifact_bucket_force_destroy

  tags = merge(var.tags, { Name = "${local.name}-pipeline-artifacts" })
}

resource "aws_s3_bucket_versioning" "artifacts" {
  count  = local.create_artifact_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  count  = local.create_artifact_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.artifact_kms_key_arn == null ? "AES256" : "aws:kms"
      kms_master_key_id = var.artifact_kms_key_arn
    }
    bucket_key_enabled = var.artifact_kms_key_arn != null
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  count  = local.create_artifact_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  count  = local.create_artifact_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    id     = "expire-old-artifacts"
    status = "Enabled"
    filter {}

    expiration {
      days = var.artifact_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.artifact_noncurrent_expiration_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.artifacts]
}

###############################################################################
# GitHub source connection (optional)
###############################################################################
resource "aws_codestarconnections_connection" "github" {
  count         = var.create_github_connection ? 1 : 0
  name          = substr("${local.name}-github", 0, 32)
  provider_type = "GitHub"

  tags = merge(var.tags, { Name = "${local.name}-github" })
}

###############################################################################
# CodeBuild project (optional)
###############################################################################
resource "aws_cloudwatch_log_group" "codebuild" {
  #checkov:skip=CKV_AWS_158:Log-group CMK is consumer-supplied via kms_key_id; AWS-managed encryption by default
  count             = var.codebuild == null ? 0 : 1
  name              = "/aws/codebuild/${local.name}-build"
  retention_in_days = var.codebuild.log_retention_days

  tags = merge(var.tags, { Name = "${local.name}-build-logs" })
}

resource "aws_codebuild_project" "this" {
  #checkov:skip=CKV_AWS_147:CodeBuild CMK is consumer-supplied; AWS-managed key by default
  count        = var.codebuild == null ? 0 : 1
  name         = "${local.name}-build"
  service_role = var.codebuild_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild.compute_type
    image                       = var.codebuild.image
    type                        = var.codebuild.type
    image_pull_credentials_type = var.codebuild.image_pull_credentials_type
    privileged_mode             = var.codebuild.privileged_mode

    dynamic "environment_variable" {
      for_each = var.codebuild.environment_variables
      content {
        name  = environment_variable.key
        value = environment_variable.value.value
        type  = environment_variable.value.type
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild[0].name
      status     = "ENABLED"
    }
  }

  source {
    type      = var.codebuild.source_type
    buildspec = var.codebuild.buildspec
  }

  tags = merge(var.tags, { Name = "${local.name}-build" })

  lifecycle {
    precondition {
      condition     = var.codebuild_role_arn != null
      error_message = "codebuild_role_arn must be set when codebuild is configured."
    }
  }
}

###############################################################################
# Pipeline
###############################################################################
resource "aws_codepipeline" "this" {
  #checkov:skip=CKV_AWS_219:CodePipeline artifact-store CMK is consumer-supplied
  name           = "${local.name}-pipeline"
  role_arn       = var.codepipeline_role_arn
  pipeline_type  = var.pipeline_type
  execution_mode = var.execution_mode

  artifact_store {
    location = local.artifact_bucket
    type     = "S3"
  }

  dynamic "trigger" {
    for_each = var.push_trigger == null ? [] : [var.push_trigger]
    content {
      provider_type = "CodeStarSourceConnection"
      git_configuration {
        source_action_name = trigger.value.source_action_name
        push {
          branches {
            includes = trigger.value.branches
          }
          dynamic "file_paths" {
            for_each = length(trigger.value.file_paths) > 0 ? [trigger.value.file_paths] : []
            content {
              includes = file_paths.value
            }
          }
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.stages
    content {
      name = stage.value.name

      dynamic "action" {
        for_each = stage.value.actions
        content {
          name             = action.value.name
          category         = action.value.category
          owner            = action.value.owner
          provider         = action.value.provider
          version          = action.value.version
          input_artifacts  = action.value.input_artifacts
          output_artifacts = action.value.output_artifacts
          namespace        = action.value.namespace
          region           = action.value.region
          run_order        = action.value.run_order
          role_arn         = action.value.role_arn
          configuration = merge(
            lookup(local.action_default_configuration, action.value.provider, {}),
            coalesce(action.value.configuration, {}),
          )
        }
      }
    }
  }

  tags = merge(var.tags, { Name = "${local.name}-pipeline" })
}
