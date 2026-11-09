output "alb_arn" {
  description = "ARN of the load balancer."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the load balancer."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route 53 hosted zone ID of the load balancer (for alias records)."
  value       = aws_lb.this.zone_id
}

output "security_group_id" {
  description = "ID of the load balancer's security group."
  value       = aws_security_group.this.id
}

output "target_group_arn" {
  description = "ARN of the target group (pass to aws-ecs-service)."
  value       = aws_lb_target_group.this.arn
}

output "listener_arn" {
  description = "ARN of the listener."
  value       = aws_lb_listener.this.arn
}
