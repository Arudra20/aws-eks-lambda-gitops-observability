output "state_bucket_name" {
  description = "S3 bucket name used for Terraform remote state."
  value       = aws_s3_bucket.telecom_state.bucket
}

output "state_bucket_arn" {
  description = "S3 bucket ARN used for Terraform remote state."
  value       = aws_s3_bucket.telecom_state.arn
}

output "dynamodb_lock_table_name" {
  description = "Legacy DynamoDB lock table name, if created."
  value       = try(aws_dynamodb_table.terraform_locks[0].name, null)
}
