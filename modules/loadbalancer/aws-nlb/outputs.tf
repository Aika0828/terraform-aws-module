output "nlb_arn" {
  description = "ARN of the network load balancer."
  value       = aws_lb.this.arn
}

output "nlb_dns_name" {
  description = "DNS name of the network load balancer."
  value       = aws_lb.this.dns_name
}

output "nlb_zone_id" {
  description = "Route 53 hosted zone ID of the load balancer (for alias records)."
  value       = aws_lb.this.zone_id
}

output "security_group_id" {
  description = "ID of the load balancer's security group."
  value       = aws_security_group.this.id
}

output "target_group_arn" {
  description = "ARN of the target group (pass to the service / autoscaling group)."
  value       = aws_lb_target_group.this.arn
}

output "target_group_name" {
  description = "Name of the target group."
  value       = aws_lb_target_group.this.name
}

output "listener_arns" {
  description = "ARNs of the listeners, in the order of the listeners input."
  value       = aws_lb_listener.this[*].arn
}
