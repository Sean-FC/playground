resource "aws_ssm_parameter" "postgres" {
  name = "/${module.context.stage}/eso/postgres"
  type = "SecureString"
  value = jsonencode({
    admin-password    = local.secrets_main.postgres.admin_password
    platform-password = local.secrets_main.postgres.platform_password
  })
  tags = module.context.tags
}
