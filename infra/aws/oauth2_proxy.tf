resource "aws_ssm_parameter" "oauth2_proxy_google" {
  name = "/${module.context.stage}/eso/oauth2-proxy/google"
  type = "SecureString"
  value = jsonencode({
    client-id     = local.secrets_main.oauth2_proxy.google.client_id
    client-secret = local.secrets_main.oauth2_proxy.google.client_secret
    cookie-secret = local.secrets_main.oauth2_proxy.google.cookie_secret
  })

  tags = module.context.tags
}

resource "aws_ssm_parameter" "oauth2_proxy" {
  name = "/${module.context.stage}/eso/oauth2-proxy/common"
  type = "SecureString"
  value = jsonencode({
    restricted_user_access = local.secrets_main.oauth2_proxy.restricted_user_access
  })

  tags = module.context.tags
}
