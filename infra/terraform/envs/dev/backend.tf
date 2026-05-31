terraform {
  backend "s3" {
    bucket  = "eks-lambda-gitops-dev"
    key     = "ekslambda/dev/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }
}
