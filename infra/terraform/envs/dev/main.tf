locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = var.github_repo
  }
}

module "network" {
  source      = "../../modules/network"
  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
  azs         = var.azs
  tags        = local.common_tags
}

module "ecr" {
  source          = "../../modules/ecr"
  repository_name = "${local.name_prefix}/order-api"
  tags            = local.common_tags
}

module "github_oidc" {
  source        = "../../modules/github-oidc"
  name_prefix   = local.name_prefix
  github_org    = var.github_org
  github_repo   = var.github_repo
  github_branch = var.github_branch
  aws_region    = var.aws_region
  ecr_repo_arn  = module.ecr.repository_arn
  tags          = local.common_tags
}

module "eks" {
  source                  = "../../modules/eks"
  cluster_name            = "${local.name_prefix}-eks"
  kubernetes_version      = var.kubernetes_version
  vpc_id                  = module.network.vpc_id
  private_subnet_ids      = module.network.private_subnet_ids
  github_actions_role_arn = module.github_oidc.github_actions_role_arn
  tags                    = local.common_tags
}

module "lambda" {
  source        = "../../modules/lambda"
  function_name = "${local.name_prefix}-order-processor"
  source_dir    = "${path.root}/../../../../lambda/order-processor"
  environment   = var.environment
  tags          = local.common_tags
}

module "irsa_lambda_invoke" {
  source               = "../../modules/irsa-lambda-invoke"
  name_prefix          = local.name_prefix
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  namespace            = var.app_namespace
  service_account_name = "${local.name_prefix}-order-api-sa"
  lambda_function_arn  = module.lambda.lambda_function_arn
  tags                 = local.common_tags
}
