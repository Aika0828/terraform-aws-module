output "ecr_repository_url" {
  description = "URL of the app ECR repository (push images here)."
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the app ECR repository."
  value       = aws_ecr_repository.app.arn
}

output "service_name" {
  description = "Name of the ECS service."
  value       = module.service.service_name
}

output "service_security_group_id" {
  description = "Security group ID of the ECS tasks."
  value       = module.service.security_group_id
}

output "alb_dns_name" {
  description = "ALB DNS name (null when create_alb = false)."
  value       = try(module.alb[0].alb_dns_name, null)
}

output "alb_arn" {
  description = "ALB ARN (null when create_alb = false)."
  value       = try(module.alb[0].alb_arn, null)
}

output "target_group_arn" {
  description = "Target group ARN (null when create_alb = false)."
  value       = try(module.alb[0].target_group_arn, null)
}
