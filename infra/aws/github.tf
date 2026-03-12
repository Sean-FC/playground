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
