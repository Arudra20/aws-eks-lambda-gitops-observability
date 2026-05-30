locals {
  oidc_provider_host = replace(var.oidc_provider_url, "https://", "")
  role_name          = "${var.name_prefix}-order-api-lambda-invoke-role"
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = var.tags
}

data "aws_iam_policy_document" "lambda_invoke" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction"
    ]

    resources = [
      var.lambda_function_arn
    ]
  }
}

resource "aws_iam_policy" "this" {
  name   = "${local.role_name}-policy"
  policy = data.aws_iam_policy_document.lambda_invoke.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
