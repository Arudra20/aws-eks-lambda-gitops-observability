variable "aws_region" {
  description = "AWS region where the Terraform backend bucket will be created."
  type        = string
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name used for Terraform remote state."
  type        = string
}

variable "enable_legacy_dynamodb_lock_table" {
  description = "Creates a DynamoDB table for legacy Terraform state locking. Prefer S3 use_lockfile for new projects."
  type        = bool
  default     = false
}

variable "dynamodb_lock_table_name" {
  description = "DynamoDB lock table name if legacy locking is enabled."
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags applied to backend resources."
  type        = map(string)
  default     = {}
}
