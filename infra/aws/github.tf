locals {
  github = {
    repo = "playground"
  }
}

# Deployment key for ArgoCD accessing github
resource "tls_private_key" "argocd_deploy_key" {
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "argocd" {
  repository = local.github.repo
  title      = join(module.context.delimiter, [module.context.id, "argocd"])
  key        = tls_private_key.argocd_deploy_key.public_key_openssh
  read_only  = true
}

resource "aws_ssm_parameter" "github_actions_runners" {
  count = var.k3s_enabled ? 1 : 0
  name  = "/${module.context.stage}/eso/github-actions-runners"
  type  = "SecureString"
  value = jsonencode({
    github_token = local.secrets_main.github.pat
  })

  tags = module.context.tags
}
