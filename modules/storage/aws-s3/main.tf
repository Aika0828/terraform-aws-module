locals {
  bucket_name = var.bucket_name != null ? var.bucket_name : "${var.project_name}-${var.bucket_suffix}-${var.environment}"
}

resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = merge(var.tags, { Name = local.bucket_name })
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption.sse_algorithm
      kms_master_key_id = var.encryption.sse_algorithm == "aws:kms" ? var.encryption.kms_key_id : null
    }
    bucket_key_enabled = var.encryption.bucket_key_enabled
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  #checkov:skip=CKV_AWS_53:Public access is blocked by default (block_public_access defaults all true); flags are consumer-overridable
  #checkov:skip=CKV_AWS_54:Public access is blocked by default (block_public_access defaults all true); flags are consumer-overridable
  #checkov:skip=CKV_AWS_55:Public access is blocked by default (block_public_access defaults all true); flags are consumer-overridable
  #checkov:skip=CKV_AWS_56:Public access is blocked by default (block_public_access defaults all true); flags are consumer-overridable
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_access.block_public_acls
  block_public_policy     = var.block_public_access.block_public_policy
  ignore_public_acls      = var.block_public_access.ignore_public_acls
  restrict_public_buckets = var.block_public_access.restrict_public_buckets
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  #checkov:skip=CKV_AWS_300:Abort-incomplete-multipart is set per consumer-defined lifecycle rule
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = { for r in var.lifecycle_rules : r.id => r }
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [rule.value.expiration_days] : []
        content {
          days = expiration.value
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration_days != null ? [rule.value.noncurrent_version_expiration_days] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days != null ? [rule.value.abort_incomplete_multipart_upload_days] : []
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
    }
  }
}

# Optional bucket policy — passed in as a rendered JSON string; no IAM created.
resource "aws_s3_bucket_policy" "this" {
  count = var.bucket_policy != null ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy

  # Ensure the public access block is in place before attaching a policy.
  depends_on = [aws_s3_bucket_public_access_block.this]
}
