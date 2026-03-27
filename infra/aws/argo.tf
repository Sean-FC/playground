data "aws_iam_policy_document" "argo_image_updater_assume" {
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
      values   = ["system:serviceaccount:argo:argo-image-updater"]
    }
  }
}

resource "aws_iam_role" "argo_image_updater" {
  name               = join(module.context.delimiter, [module.context.id, "argo-image-updater"])
  assume_role_policy = data.aws_iam_policy_document.argo_image_updater_assume.json

  tags = module.context.tags
}

data "aws_iam_policy_document" "argo_image_updater" {
  statement {
    sid    = "ReadECR"
    effect = "Allow"
    actions = [
      "ecr:GetRegistryPolicy",
      "ecr:DescribeImageScanFindings",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRegistry",
      "ecr:DescribeImageReplicationStatus",
      "ecr:ListTagsForResource",
      "ecr:ListImages",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetRepositoryPolicy",
      "ecr:GetLifecyclePolicy",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "argo_image_updater" {
  name   = join(module.context.delimiter, [module.context.id, "argo-image-updater"])
  policy = data.aws_iam_policy_document.argo_image_updater.json
}

resource "aws_iam_role_policy_attachment" "argo_image_updater" {
  role       = aws_iam_role.argo_image_updater.name
  policy_arn = aws_iam_policy.argo_image_updater.arn
}
