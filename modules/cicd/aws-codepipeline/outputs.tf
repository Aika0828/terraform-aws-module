output "pipeline_name" {
  description = "Name of the CodePipeline."
  value       = aws_codepipeline.this.name
}

output "pipeline_arn" {
  description = "ARN of the CodePipeline."
  value       = aws_codepipeline.this.arn
}

output "artifact_bucket_name" {
  description = "Name of the S3 bucket used for pipeline artifacts (created or supplied)."
  value       = local.artifact_bucket
}

output "artifact_bucket_arn" {
  description = "ARN of the created artifact bucket (null when an existing bucket name was supplied)."
  value       = local.create_artifact_bucket ? aws_s3_bucket.artifacts[0].arn : null
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project (null when no codebuild is configured)."
  value       = var.codebuild == null ? null : aws_codebuild_project.this[0].name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project (null when no codebuild is configured)."
  value       = var.codebuild == null ? null : aws_codebuild_project.this[0].arn
}

output "codebuild_log_group_name" {
  description = "Name of the CodeBuild CloudWatch log group (null when no codebuild is configured)."
  value       = var.codebuild == null ? null : aws_cloudwatch_log_group.codebuild[0].name
}

output "github_connection_arn" {
  description = "ARN of the CodeStar GitHub connection in use (created or supplied)."
  value       = local.connection_arn
}
