output "linked_account_id" {
  description = "ID of the New Relic linked AWS account."
  value       = newrelic_cloud_aws_link_account.this.id
}

output "linked_account_name" {
  description = "Display name of the New Relic linked AWS account."
  value       = newrelic_cloud_aws_link_account.this.name
}
