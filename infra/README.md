# Personal Account Infra
Terraform for playing around with my development account

## Getting Started 🎬
### Tooling 🛠
- [tfenv](https://github.com/tfutils/tfenv): Terraform version manager
- [terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/#install-via-a-package-manager): DRY wrapper for Terraform (dev + prod accounts)
- [pre-commit](https://pre-commit.com): Git hooks for consistency
- [tflint](https://github.com/terraform-linters/tflint): Linting
- [sops](https://github.com/getsops/sops): Secrets OPerationS (implicitly used)

Ensure you're using the pinned version of terraform:
```bash
#!/usr/bin/env bash
tfenv install `cat .terraform-version`
```

### Layout 🗺
- [bootstrap](./bootstrap): Resources created _once_
- [aws](./aws): General

#### Why?
- Idea for the bootstrap is standardized resources once upon account creation that help getting other modules running or potentially managed by another team such as SRE in an enterprise setting
  - For example a KMS key for SOPS, OIDC provider for Gitlab CI/CD, etc
- The bootstrap folder is _always_ applied first to the account
- This essentially means one can completely destroy every resource under the every other module and then re-create it using a single `terragrunt apply` operation

## FAQs 🙋
- [General setup](FAQ.md).
