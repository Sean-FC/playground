data "aws_iam_policy_document" "cert_manager_route53" {
  count = var.k3s_enabled ? 1 : 0

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
  count  = var.k3s_enabled ? 1 : 0
  name   = join(module.context.delimiter, [module.context.id, "cert-manager", "route53"])
  policy = data.aws_iam_policy_document.cert_manager_route53[0].json
}

resource "aws_iam_role_policy_attachment" "cert_manager_route53" {
  count = var.k3s_enabled ? 1 : 0
  # Master currently bound to EIP to avoid an ALB
  role       = aws_iam_role.k3s_server_node[0].name
  policy_arn = aws_iam_policy.cert_manager_route53[0].arn
}
