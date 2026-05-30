resource "aws_s3_bucket" "ekslambda" {
  bucket = var.state_bucket_name

  tags = merge(var.common_tags, {
    Name = var.state_bucket_name
  })
}
resource "aws_s3_bucket_public_access_block" "ekslambda" {
  bucket = aws_s3_bucket.ekslambda.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ekslambda" {
  bucket = aws_s3_bucket.ekslambda.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  count = var.enable_legacy_dynamodb_lock_table ? 1 : 0

  name         = coalesce(var.dynamodb_lock_table_name, "${var.state_bucket_name}-locks")
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.common_tags, {
    Name = coalesce(var.dynamodb_lock_table_name, "${var.state_bucket_name}-locks")
  })
}

resource "aws_s3_bucket_versioning" "ekslambda" {
  bucket = aws_s3_bucket.ekslambda.id

  versioning_configuration {
    status = "Enabled"
  }
}
