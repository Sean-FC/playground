resource "aws_ssm_parameter" "crowdsec" {
  count = var.k3s_enabled ? 1 : 0
  name  = "/${module.context.stage}/eso/crowdsec"
  type  = "SecureString"
  value = jsonencode({
    csLapiSecret      = local.secrets_main.crowdsec.cs_lapi_secret
    registrationToken = local.secrets_main.crowdsec.registration_token
    enrollKey         = local.secrets_main.crowdsec.enroll_key
    traefikBouncerKey = local.secrets_main.crowdsec.traefik_bouncer_key
  })

  tags = module.context.tags
}
