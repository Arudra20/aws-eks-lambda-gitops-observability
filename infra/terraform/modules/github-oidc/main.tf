data "aws_caller_identity" "current" {}

locals {
  github_provider_url = "https://token.actions.githubusercontent.com"
  github_provider_host = "token.actions.githubusercontent.com"
  repo_subject = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url = local.github_provider_url

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-github-oidc"
  })
}

data "aws_iam_openid_connect_provider" "github_existing" {
  count = var.create_oidc_provider ? 0 : 1
  url   = local.github_provider_url
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github_existing[0].arn
}

data "aws_iam_policy_document" "github_trust" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_provider_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_provider_host}:sub"
      values   = [local.repo_subject]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.name_prefix}-gha-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
  tags               = var.tags
}

data "aws_iam_policy_document" "github_actions_policy" {
  statement {
    sid    = "AllowEcrPushPull"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = ["*", var.ecr_repo_arn]
  }

  statement {
    sid    = "AllowEksDescribe"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowLambdaDeploy"
    effect = "Allow"
    actions = [
      "lambda:GetFunction",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCallerIdentity"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions" {
  name   = "${var.name_prefix}-gha-deploy-policy"
  policy = data.aws_iam_policy_document.github_actions_policy.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
