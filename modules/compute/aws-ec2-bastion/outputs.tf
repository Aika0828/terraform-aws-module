output "instance_id" {
  description = "ID of the bastion EC2 instance."
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the bastion EC2 instance."
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IP address of the bastion."
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP address of the bastion (null when associate_public_ip = false)."
  value       = aws_instance.this.public_ip
}

output "security_group_id" {
  description = "ID of the bastion's security group."
  value       = aws_security_group.this.id
}

output "ami_id" {
  description = "AMI ID the bastion was launched from."
  value       = aws_instance.this.ami
}
