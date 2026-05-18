resource "aws_ssm_parameter" "renovate" {
  name = "/${module.context.stage}/eso/renovate"
  type = "SecureString"
  value = jsonencode({
    "github-app-id"  = tostring(local.secrets_main.renovate.github.app_id)
    "github-app-pem" = local.secrets_main.renovate.github.app_pem
    "license-key"    = local.secrets_main.renovate.license_key
  })

  tags = module.context.tags
}
