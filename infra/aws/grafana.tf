resource "aws_ssm_parameter" "grafana_admin" {
  count = var.k3s_enabled ? 1 : 0
  name  = "/${module.context.stage}/eso/grafana-admin"
  type  = "SecureString"
  value = jsonencode({
    user     = local.secrets_main.grafana.admin_user
    password = local.secrets_main.grafana.admin_password
  })

  tags = module.context.tags
}
