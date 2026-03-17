output "default_secrets_kms_arn" {
  value = aws_kms_key.external.arn
}

output "default_secrets_kms_decrypt" {
  value = aws_iam_policy.external_decrypt.arn
}

output "gitlab_oidc_arn" {
  value = aws_iam_openid_connect_provider.gitlab.arn
}
