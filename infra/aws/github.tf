locals {
  github = {
    repo = "playground"
  }
}

# Deployment key for ArgoCD accessing github
resource "tls_private_key" "argocd_deploy_key" {
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "argocd" {
  repository = local.github.repo
  title      = join(module.context.delimiter, [module.context.id, "argocd"])
  key        = tls_private_key.argocd_deploy_key.public_key_openssh
  read_only  = true
}

resource "aws_ssm_parameter" "github_actions_runners" {
  count = var.k3s_enabled ? 1 : 0
  name  = "/${module.context.stage}/eso/github-actions-runners"
  type  = "SecureString"
  value = jsonencode({
    github_token = local.secrets_main.github.pat
  })

  tags = module.context.tags
}

# Default role that can be used by GHA scale-set runners
data "aws_iam_policy_document" "default_gha_runner_assume" {
  count = var.k3s_enabled ? 1 : 0

  statement {
    sid     = "AllowK3sServiceAccountAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.k3s.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.k3s.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${replace(aws_iam_openid_connect_provider.k3s.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:gha:*"]
    }
  }
}

resource "aws_iam_role" "default_gha_runner" {
  count              = var.k3s_enabled ? 1 : 0
  name               = join(module.context.delimiter, [module.context.stage, "default", "gha", "runner"])
  assume_role_policy = data.aws_iam_policy_document.default_gha_runner_assume[0].json

  tags = module.context.tags
}

data "aws_iam_policy_document" "default_gha_runner" {
  count = var.k3s_enabled ? 1 : 0

  statement {
    sid    = "StsCallerIdentity"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EcrAuthorization"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EcrReadWrite"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [
      "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/*",
    ]
  }

  # https://docs.aws.amazon.com/signer/latest/developerguide/image-signing-prerequisites.html
  statement {
    sid    = "SignerNotation"
    effect = "Allow"
    actions = [
      "signer:SignPayload",
      "signer:GetRevocationStatus",
    ]
    resources = [aws_signer_signing_profile.notation_oci.arn]
  }

  statement {
    sid    = "ReadParameterStoreCI"
    effect = "Allow"
    actions = [
      "ssm:GetParameter*",
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter/${module.context.stage}/ci/github-actions-runners/*",
    ]
  }

  statement {
    sid    = "DescribeParameterStoreCI"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "default_gha_runner" {
  count  = var.k3s_enabled ? 1 : 0
  name   = join(module.context.delimiter, [module.context.stage, "default", "gha", "runner"])
  policy = data.aws_iam_policy_document.default_gha_runner[0].json
}

resource "aws_iam_role_policy_attachment" "default_gha_runner" {
  count      = var.k3s_enabled ? 1 : 0
  role       = aws_iam_role.default_gha_runner[0].name
  policy_arn = aws_iam_policy.default_gha_runner[0].arn
}
