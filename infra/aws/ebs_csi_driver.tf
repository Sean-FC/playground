data "aws_iam_policy_document" "ebs_csi_driver_assume" {
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
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  count              = var.k3s_enabled ? 1 : 0
  name               = join(module.context.delimiter, [module.context.id, "ebs-csi-controller"])
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume[0].json

  tags = module.context.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  count      = var.k3s_enabled ? 1 : 0
  role       = aws_iam_role.ebs_csi_driver[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Note: we rely on the key policy for managed key aws/ebs for encrypted volume management
# hence no further policy
