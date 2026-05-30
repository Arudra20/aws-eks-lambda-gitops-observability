terraform {
  backend "s3" {
    bucket         = "eks_lambda"
    key            = "ekslambda/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "ekslambda-dev-tf-locks"
    encrypt        = true
  }
}
