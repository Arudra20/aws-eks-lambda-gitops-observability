param(
    [string]$AwsRegion = "ap-south-1",
    [string]$BucketName,
    [string]$LockTable = "ekslambda-dev-tf-locks"
)

$ErrorActionPreference = "Stop"

if (-not $BucketName) {
    throw "Pass -BucketName. Example: .\01-bootstrap-backend.ps1 -BucketName ekslambda-dev-tfstate-123456789012"
}

aws s3api create-bucket `
  --bucket $BucketName `
  --region $AwsRegion `
  --create-bucket-configuration LocationConstraint=$AwsRegion

aws s3api put-bucket-versioning `
  --bucket $BucketName `
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption `
  --bucket $BucketName `
  --server-side-encryption-configuration '{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}'

aws dynamodb create-table `
  --table-name $LockTable `
  --attribute-definitions AttributeName=LockID,AttributeType=S `
  --key-schema AttributeName=LockID,KeyType=HASH `
  --billing-mode PAY_PER_REQUEST `
  --region $AwsRegion

Write-Host "Backend created. Now copy backend.hcl.example to backend.hcl and update bucket name."
