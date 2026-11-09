output "table_name" {
  description = "Name of the DynamoDB table."
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table."
  value       = aws_dynamodb_table.this.arn
}

output "table_id" {
  description = "Name (ID) of the DynamoDB table."
  value       = aws_dynamodb_table.this.id
}

output "stream_arn" {
  description = "ARN of the table's DynamoDB stream (null when streams are disabled)."
  value       = aws_dynamodb_table.this.stream_arn
}

output "hash_key" {
  description = "Partition (hash) key of the table."
  value       = aws_dynamodb_table.this.hash_key
}

output "range_key" {
  description = "Sort (range) key of the table (null when none)."
  value       = aws_dynamodb_table.this.range_key
}
