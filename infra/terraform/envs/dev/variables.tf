variable "project" {
  description = "Short project code used in resource names."
  type        = string
  default     = "ekslambda"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "ap-south-1"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.31"
}

variable "vpc_cidr" {
  description = "VPC CIDR."
  type        = string
  default     = "10.40.0.0/16"
}

variable "azs" {
  description = "Availability zones."
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "github_org" {
  description = "GitHub org/user."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
  default     = "eks-lambda-gitops-observability"
}

variable "github_branch" {
  description = "Allowed GitHub branch for OIDC assume role."
  type        = string
  default     = "main"
}

variable "app_namespace" {
  description = "Kubernetes namespace for application."
  type        = string
  default     = "ekslambda-dev"
}
