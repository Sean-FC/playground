locals {
  airflow_task_log_prefix = "task-logs"
  airflow_service_account_subjects = [
    "system:serviceaccount:airflow:airflow",
    "system:serviceaccount:airflow:airflow-api-server",
    "system:serviceaccount:airflow:airflow-dag-processor",
    "system:serviceaccount:airflow:airflow-scheduler",
    "system:serviceaccount:airflow:airflow-triggerer",
    "system:serviceaccount:airflow:airflow-webserver",
    "system:serviceaccount:airflow:airflow-worker",
  ]
}

resource "aws_ssm_parameter" "airflow" {
  name = "/${module.context.stage}/eso/airflow"
  type = "SecureString"
  value = jsonencode({
    fernet-key           = local.secrets_main.airflow.fernet_key
    api-secret-key       = local.secrets_main.airflow.api_secret_key
    jwt-secret           = local.secrets_main.airflow.jwt_secret
    webserver-secret-key = local.secrets_main.airflow.webserver_secret_key
    git-sync-ssh-key     = local.secrets_main.airflow.git_sync_ssh_key
    aws-region           = data.aws_region.current.region
    remote-log-bucket    = aws_s3_bucket.airflow_task_logs.bucket
    remote-log-prefix    = local.airflow_task_log_prefix
    role-arn             = aws_iam_role.airflow.arn
  })
  tags = module.context.tags
}

resource "aws_s3_bucket" "airflow_task_logs" {
  bucket        = join(module.context.delimiter, ["seanfc", module.context.id, "airflow", "task", "logs"])
  force_destroy = false
  tags          = module.context.tags
}

resource "aws_s3_bucket_public_access_block" "airflow_task_logs" {
  bucket                  = aws_s3_bucket.airflow_task_logs.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "airflow_task_logs" {
  bucket = aws_s3_bucket.airflow_task_logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "airflow_task_logs" {
  bucket = aws_s3_bucket.airflow_task_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "airflow_task_logs" {
  bucket = aws_s3_bucket.airflow_task_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "airflow_task_logs" {
  bucket = aws_s3_bucket.airflow_task_logs.id

  rule {
    id     = "task-log-retention"
    status = "Enabled"

    filter {
      prefix = "${local.airflow_task_log_prefix}/"
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

data "aws_iam_policy_document" "airflow_task_logs_bucket" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.airflow_task_logs.arn,
      "${aws_s3_bucket.airflow_task_logs.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "airflow_task_logs" {
  bucket = aws_s3_bucket.airflow_task_logs.id
  policy = data.aws_iam_policy_document.airflow_task_logs_bucket.json
}

data "aws_iam_policy_document" "airflow_assume" {
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
      values   = local.airflow_service_account_subjects
    }
  }
}

resource "aws_iam_role" "airflow" {
  name               = join(module.context.delimiter, [module.context.id, "airflow"])
  assume_role_policy = data.aws_iam_policy_document.airflow_assume.json

  tags = module.context.tags
}

data "aws_iam_policy_document" "airflow_task_logs" {
  statement {
    sid       = "AllowListAirflowTaskLogs"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.airflow_task_logs.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        local.airflow_task_log_prefix,
        "${local.airflow_task_log_prefix}/*",
      ]
    }
  }

  statement {
    sid    = "AllowReadWriteAirflowTaskLogs"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.airflow_task_logs.arn}/${local.airflow_task_log_prefix}/*",
    ]
  }

  statement {
    sid       = "AllowGetAirflowTaskLogBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.airflow_task_logs.arn]
  }
}

resource "aws_iam_policy" "airflow_task_logs" {
  name   = join(module.context.delimiter, [module.context.id, "airflow", "task", "logs"])
  policy = data.aws_iam_policy_document.airflow_task_logs.json
}

resource "aws_iam_role_policy_attachment" "airflow_task_logs" {
  role       = aws_iam_role.airflow.name
  policy_arn = aws_iam_policy.airflow_task_logs.arn
}

output "airflow_task_logs_bucket" {
  value = aws_s3_bucket.airflow_task_logs.bucket
}

output "airflow_role_arn" {
  value = aws_iam_role.airflow.arn
}
