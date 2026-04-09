resource "tailscale_tailnet_key" "k3s_tailnet_server" {
  count               = var.k3s_enabled ? 1 : 0
  reusable            = true
  ephemeral           = false
  preauthorized       = true
  expiry              = 7776000
  recreate_if_invalid = "always"
  description         = "K3s API Server"
}

resource "tailscale_acl" "tag_owners" {
  acl = <<EOF
    {
      "tagOwners": {
        "tag:k8s-operator": [],
        "tag:k8s": ["tag:k8s-operator"]
      }
    }
  EOF
}

resource "tailscale_oauth_client" "k3s_tailnet_operator" {
  description = "TailScale Operator"
  scopes      = ["devices:core", "auth_keys", "services"]
  tags        = ["tag:k8s-operator"]
}

resource "aws_ssm_parameter" "tailscale" {
  name = "/${module.context.stage}/eso/tailscale"
  type = "SecureString"
  value = jsonencode({
    client_id     = tailscale_oauth_client.k3s_tailnet_operator.id
    client_secret = tailscale_oauth_client.k3s_tailnet_operator.key
  })

  tags = module.context.tags
}
