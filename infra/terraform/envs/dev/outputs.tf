output "cluster_name" {
  value = module.eks.cluster_name
}

output "aws_region" {
  value = var.aws_region
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "github_actions_role_arn" {
  value = module.github_oidc.github_actions_role_arn
}

output "lambda_function_name" {
  value = module.lambda.lambda_function_name
}

output "lambda_invoke_irsa_role_arn" {
  value = module.irsa_lambda_invoke.role_arn
}

output "update_kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
