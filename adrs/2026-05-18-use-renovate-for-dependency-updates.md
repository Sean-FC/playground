# Use Renovate For Dependency Updates

## Status
Accepted

## Context
It's desired to have automated dependency updates tools and definitions under the repository.

The dependency surface primarily spans currently:
- Helm chart dependencies under `argo/charts/**`
- Terraform dependencies under `infra/**`
- Terragrunt-managed infrastructure, including generated Terraform source driven from `infra/terragrunt.common.hcl`

Considered using Dependabot because it is built into GitHub and simpler to operate. However, the repository structure makes two things important:
- Terragrunt support
- Simpler configuration for grouping Helm updates by chart

## Options Considered
- Dependabot
- Renovate

## Decision
Use **Renovate** because it better fits this repository's Terragrunt usage and gives us simpler, more flexible control over Helm update grouping.

## Consequences
### Positive
- Renovate can manage Helm, Terraform, and Terragrunt in one tool.  Also supports Python and Typescript for later.
- Renovate provides more flexible grouping rules for Helm charts than Dependabot.
- Renovate can be extended to cover dependencies embedded in generated-source patterns such as `infra/terragrunt.common.hcl`.

### Negative
- Renovate requires self-hosting and operational setup in the cluster.
- Renovate configuration is more involved than a minimal Dependabot setup.

### Miscellaneous
- Dependabot was considered and would have been simpler operationally, but it was less suitable for this repository's Terragrunt layout and Helm grouping requirements.
