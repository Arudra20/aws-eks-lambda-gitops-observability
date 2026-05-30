variable "name_prefix" { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }
variable "namespace" { type = string }
variable "service_account_name" { type = string }
variable "lambda_function_arn" { type = string }
variable "tags" { type = map(string) }
