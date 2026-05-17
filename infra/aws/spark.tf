resource "aws_s3_bucket" "spark_logs" {
  bucket        = join(module.context.delimiter, ["seanfc", module.context.id, "spark", "logs"])
  force_destroy = true
  tags          = module.context.tags
}

resource "aws_s3_bucket_public_access_block" "spark_logs" {
  bucket                  = aws_s3_bucket.spark_logs.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "spark_logs" {
  bucket = aws_s3_bucket.spark_logs.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "spark_logs" {
  bucket = aws_s3_bucket.spark_logs.id
  rule {
    id     = "global-object-expiry"
    status = "Enabled"
    filter {
      prefix = ""
    }
    expiration {
      days = 3
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

data "aws_iam_policy_document" "spark_history_assume" {
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
      values   = ["system:serviceaccount:spark:spark-history"]
    }
  }
}

resource "aws_iam_role" "spark_history" {
  name               = join(module.context.delimiter, [module.context.id, "spark", "history"])
  assume_role_policy = data.aws_iam_policy_document.spark_history_assume.json

  tags = module.context.tags
}

data "aws_iam_policy_document" "spark_history" {
  statement {
    sid       = "AllowListSparkLogs"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.spark_logs.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "logs",
        "logs/*",
      ]
    }
  }

  statement {
    sid    = "AllowReadSparkLogs"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.spark_logs.arn}/logs/*",
    ]
  }

  statement {
    sid       = "AllowGetBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.spark_logs.arn]
  }
}

resource "aws_iam_policy" "spark_history" {
  name   = join(module.context.delimiter, [module.context.id, "spark_history"])
  policy = data.aws_iam_policy_document.spark_history.json
}

resource "aws_iam_role_policy_attachment" "spark_history" {
  role       = aws_iam_role.spark_history.name
  policy_arn = aws_iam_policy.spark_history.arn
}
