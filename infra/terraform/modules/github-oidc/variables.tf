variable "name_prefix" { type = string }
variable "github_org" { type = string }
variable "github_repo" { type = string }
variable "github_branch" { type = string }
variable "aws_region" { type = string }
variable "ecr_repo_arn" { type = string }
variable "tags" { type = map(string) }

variable "create_oidc_provider" {
  type        = bool
  default     = true
  description = "Set false if GitHub OIDC provider already exists in the AWS account."
}
