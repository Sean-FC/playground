# $1 per month by default
resource "aws_kms_key" "external" {
  description             = "Default enc|dec account key for usage with externally managed credentials, i.e. SOPS"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  multi_region            = true # Just permits, no additional cost
  policy                  = data.aws_iam_policy_document.default_kms_key_policy.json
}

resource "aws_kms_alias" "external" {
  name          = "alias/external"
  target_key_id = aws_kms_key.external.id
}

data "aws_iam_policy_document" "default_kms_key_policy" {
  statement {
    sid       = "EnableIAMUserUsage"
    actions   = ["kms:*"]
    effect    = "Allow"
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
  }
}

data "aws_iam_policy_document" "external_decrypt" {
  statement {
    sid    = "DecryptExternalSecrets"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      aws_kms_key.external.arn,
    ]
  }
}

resource "aws_iam_policy" "external_decrypt" {
  name   = join(module.context.delimiter, [module.context.id, "external", "decrypt"])
  policy = data.aws_iam_policy_document.external_decrypt.json
}
