project            = "eks_lambda"
environment        = "dev"
aws_region         = "ap-south-1"
kubernetes_version = "1.31"

github_org    = "Arudra20"
github_repo   = "EKS_Lambda"
github_branch = "main"

app_namespace = "ekslambda-dev"

vpc_cidr = "10.0.0.0/16"

azs = [
  "ap-south-1a",
  "ap-south-1b"
]
