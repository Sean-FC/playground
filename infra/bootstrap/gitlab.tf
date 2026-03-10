locals {
  gitlab = {
    name = join(module.context.delimiter, [module.context.id, "gitlab", "infra"])
    url  = "https://gitlab.com"
  }
}

data "tls_certificate" "gitlab" {
  url = "${local.gitlab.url}/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "gitlab" {
  url = local.gitlab.url

  client_id_list = [
    local.gitlab.url
  ]

  thumbprint_list = [
    data.tls_certificate.gitlab.certificates[0].sha1_fingerprint
  ]
}

resource "aws_iam_role" "gitlab_infra" {
  name                 = local.gitlab.name
  assume_role_policy   = data.aws_iam_policy_document.gitlab_assume.json
  max_session_duration = 3600 # 60 mins is min
}

data "aws_iam_policy_document" "gitlab_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      identifiers = [aws_iam_openid_connect_provider.gitlab.arn]
      type        = "Federated"
    }
    condition {
      test     = "StringLike"
      variable = "${element(split("/", local.gitlab.url, ), 2)}:sub"
      values   = ["project_path:sean.campbell/personal-account-infra:ref_type:branch:ref:*"]
    }
  }
}

resource "aws_iam_policy" "infra_deployment" {
  name   = local.gitlab.name
  policy = data.aws_iam_policy_document.infra_deployment.json
}

resource "aws_iam_role_policy_attachment" "infra_deployment" {
  role       = local.gitlab.name
  policy_arn = aws_iam_policy.infra_deployment.arn
}

data "aws_iam_policy_document" "infra_deployment" {
  statement {
    sid    = "General"
    effect = "Allow"
    not_actions = [
      "account:*",
      "billing:*",
      "organizations:*",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid    = "PreventBadExternalKMSActions"
    effect = "Deny"
    actions = [
      "kms:DisableKey",
      "kms:ScheduleKeyDeletion"
    ]
    resources = [
      aws_kms_key.external.arn
    ]
  }
  statement {
    sid    = "PreventSpecific"
    effect = "Deny"
    actions = [
      "route53:RegisterDomain",
      "route53:TransferDomain",
      "rout53:TransferDomainToAnotherAwsAccount",
      "route53:DeleteDomain",
      "route53:ViewBilling",
      "s3:DeleteBucket"
    ]
    resources = [
      "*"
    ]
  }
}
