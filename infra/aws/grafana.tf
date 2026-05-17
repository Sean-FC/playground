resource "aws_ssm_parameter" "grafana_admin" {
  name = "/${module.context.stage}/eso/grafana-admin"
  type = "SecureString"
  value = jsonencode({
    user     = local.secrets_main.grafana.admin_user
    password = local.secrets_main.grafana.admin_password
  })

  tags = module.context.tags
}
