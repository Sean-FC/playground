resource "aws_ssm_parameter" "n8n" {
  name = "/${module.context.stage}/eso/n8n"
  type = "SecureString"
  value = jsonencode({
    encryption-key      = local.secrets_main.n8n.encryption_key
    owner-email         = local.secrets_main.personal.email
    owner-password-hash = local.secrets_main.n8n.password_hash
  })

  tags = module.context.tags
}
