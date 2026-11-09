output "broker_id" {
  description = "The Amazon MQ broker identifier."
  value       = aws_mq_broker.this.id
}

output "broker_arn" {
  description = "The ARN of the Amazon MQ broker."
  value       = aws_mq_broker.this.arn
}

output "broker_name" {
  description = "The name of the Amazon MQ broker."
  value       = aws_mq_broker.this.broker_name
}

output "instances" {
  description = "Broker instances, each with its AMQPS endpoints and management console URL."
  value       = aws_mq_broker.this.instances
}

output "amqps_endpoints" {
  description = "Flattened list of AMQPS (amqps://...:5671) endpoints across broker instances."
  value       = flatten(aws_mq_broker.this.instances[*].endpoints)
}

output "console_urls" {
  description = "Management console URLs for the broker instances."
  value       = aws_mq_broker.this.instances[*].console_url
}

output "admin_username" {
  description = "Administrative RabbitMQ username."
  value       = var.admin_username
}

output "admin_password" {
  description = "Administrative RabbitMQ password."
  value       = var.admin_password
  sensitive   = true
}

output "security_group_id" {
  description = "ID of the security group created for the broker (null when create_security_group = false)."
  value       = try(aws_security_group.this[0].id, null)
}
