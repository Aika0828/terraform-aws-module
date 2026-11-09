output "parameter_arns" {
  description = "Map of parameter logical key to the parameter's ARN."
  value       = { for k, p in aws_ssm_parameter.this : k => p.arn }
}

output "parameter_names" {
  description = "Map of parameter logical key to the parameter's full name."
  value       = { for k, p in aws_ssm_parameter.this : k => p.name }
}

output "parameter_versions" {
  description = "Map of parameter logical key to the current parameter version."
  value       = { for k, p in aws_ssm_parameter.this : k => p.version }
}
