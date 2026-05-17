data "aws_iam_policy_document" "cert_manager_assume" {
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
      values   = ["system:serviceaccount:cert-manager:cert-manager"]
    }
  }
}

resource "aws_iam_role" "cert_manager" {
  name               = join(module.context.delimiter, [module.context.id, "cert-manager"])
  assume_role_policy = data.aws_iam_policy_document.cert_manager_assume.json

  tags = module.context.tags
}

data "aws_iam_policy_document" "cert_manager_route53" {
  statement {
    sid    = "ChangeStageZoneRecords"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${aws_route53_zone.stage.zone_id}",
    ]
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsRecordTypes"
      values   = ["TXT"]
    }
  }

  statement {
    sid    = "DiscoverHostedZones"
    effect = "Allow"
    actions = [
      "route53:ListHostedZonesByName",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ReadChangeStatus"
    effect = "Allow"
    actions = [
      "route53:GetChange",
    ]
    resources = [
      "arn:aws:route53:::change/*",
    ]
  }
}

resource "aws_iam_policy" "cert_manager_route53" {
  name   = join(module.context.delimiter, [module.context.id, "cert-manager", "route53"])
  policy = data.aws_iam_policy_document.cert_manager_route53.json
}

resource "aws_iam_role_policy_attachment" "cert_manager_route53" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = aws_iam_policy.cert_manager_route53.arn
}
