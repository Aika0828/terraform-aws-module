output "bucket_name" {
  description = "Name of the S3 state bucket (set as 'bucket' in the backend config)."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the S3 state bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_region" {
  description = "Region the S3 state bucket resides in."
  value       = aws_s3_bucket.this.region
}
