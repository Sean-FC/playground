locals {
  presigner = {
    name        = "presigner"
    bucket_name = join(module.context.delimiter, ["seanfc", module.context.id, "presigner"])
  }
}

data "aws_iam_policy_document" "presigner_assume" {
  statement {
    sid     = "AllowK3sServiceAccountAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.k3s.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.k3s.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.k3s.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.presigner.name}:${local.presigner.name}"]
    }
  }
}

resource "aws_iam_role" "presigner" {
  name               = join(module.context.delimiter, [module.context.id, local.presigner.name])
  assume_role_policy = data.aws_iam_policy_document.presigner_assume.json

  tags = module.context.tags
}

data "aws_iam_policy_document" "presigner" {
  statement {
    sid    = "StsCallerIdentity"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "S3List"
    effect = "Allow"
    actions = [
      "s3:List*",
    ]
    resources = [
      module.presigner_bucket.bucket_arn,
    ]
  }

  statement {
    sid    = "S3ObjectRead"
    effect = "Allow"
    actions = [
      "s3:Get*",
    ]
    resources = [
      "${module.presigner_bucket.bucket_arn}/*",
    ]
  }
}

resource "aws_iam_policy" "presigner" {
  name   = join(module.context.delimiter, [module.context.id, local.presigner.name])
  policy = data.aws_iam_policy_document.presigner.json
}

resource "aws_iam_role_policy_attachment" "presigner" {
  role       = aws_iam_role.presigner.name
  policy_arn = aws_iam_policy.presigner.arn
}


module "presigner_bucket" {
  source  = "git::https://github.com/cloudposse/terraform-aws-s3-bucket.git?ref=tags/v4.11.0"
  context = module.context

  bucket_name = join(module.context.delimiter, ["seanfc", module.context.id, local.presigner.name])

  allow_ssl_requests_only = true
  block_public_policy     = true
  bucket_key_enabled      = true
  versioning_enabled      = false
  user_enabled            = false
}

resource "aws_ssm_parameter" "presigner" {
  name = "/${module.context.stage}/eso/apps/presigner"
  type = "String"
  value = jsonencode({
    bucket = {
      default_name   = local.presigner.bucket_name
      default_region = module.presigner_bucket.bucket_region
    }
  })

  tags = module.context.tags
}
