output "distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.arn
}

output "domain_name" {
  description = "Domain name of the distribution (e.g. d123.cloudfront.net)."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID for the distribution, for alias records."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "status" {
  description = "Current status of the distribution (e.g. Deployed)."
  value       = aws_cloudfront_distribution.this.status
}

output "vpc_origin_id" {
  description = "ID of the created VPC origin, or null when none was created."
  value       = var.vpc_origin != null ? aws_cloudfront_vpc_origin.this[0].id : null
}
