data "aws_iam_policy_document" "external_secrets_operator_assume" {
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
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.k3s.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:external-secrets-operator:external-secrets-operator"]
    }
  }
}

resource "aws_iam_role" "external_secrets_operator" {
  count              = var.k3s_enabled ? 1 : 0
  name               = join(module.context.delimiter, [module.context.id, "external", "secrets", "operator"])
  assume_role_policy = data.aws_iam_policy_document.external_secrets_operator_assume[0].json

  tags = module.context.tags
}

data "aws_iam_policy_document" "external_secrets_operator" {
  count = var.k3s_enabled ? 1 : 0
  statement {
    sid    = "ListSecretsManager"
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ReadSecretsManager"
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${module.context.stage}-eso-*",
    ]
  }

  statement {
    sid    = "ReadParameterStore"
    effect = "Allow"
    actions = [
      "ssm:GetParameter*",
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter/${module.context.stage}/eso/*",
    ]
  }

  statement {
    sid    = "DescribeParameters"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
    ]
    resources = ["*"]
  }
  # Permit auth token generator
  statement {
    sid    = "GetECRAuthzToken"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeImages",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_secrets_operator" {
  count  = var.k3s_enabled ? 1 : 0
  name   = join(module.context.delimiter, [module.context.id, "external-secrets-operator", "read"])
  policy = data.aws_iam_policy_document.external_secrets_operator[0].json
}

resource "aws_iam_role_policy_attachment" "external_secrets_operator" {
  count      = var.k3s_enabled ? 1 : 0
  role       = aws_iam_role.external_secrets_operator[0].name
  policy_arn = aws_iam_policy.external_secrets_operator[0].arn
}
