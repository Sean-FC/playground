# Use n8n For simple workflow automation

## Status
Accepted

## Context
Desire a lightweight way to prototype and run simple automations in a self-hosted platform without turning every integration into a custom service or complex dag.

n8n can be powerful and flexible, cost-effective when self-hosted, and useful when data/workflow ownership matters. It also calls out the operational and learning-curve cost of self-hosting and using a node-based workflow builder. Those tradeoffs match this repository: the platform already runs Kubernetes, Helm, External Secrets, Postgres, and Gateway API, so the self-hosting burden is acceptable for dev, but n8n should not become an ungoverned replacement for production services.

## Options Considered
- Build each automation as a custom application or script
- Use a hosted automation platform such as Zapier, Make, or a no-code AI-agent product
- Self-host n8n in the dev cluster

## Decision
Use **self-hosted n8n in the dev cluster** for low-risk workflow automation and operational prototypes.

n8n will be deployed from the actively maintained community Helm chart, backed by the shared Postgres service, and configured through External Secrets for sensitive values such as the encryption key and owner account password hash.
Workflows will be stored in git as importable JSON under `argo/charts/data/n8n/workflows`.

## Consequences
### Positive
- Provides a fast visual workflow surface for operational automations.
- Keeps workflow execution and sensitive data inside our infrastructure.
- Avoids per-execution SaaS pricing for dev experiments and recurring checks.
- Allows workflows to integrate with existing platform services such as the Kubernetes MCP.
- Keeps workflow definitions reviewable when exported and stored in git.

### Negative
- Adds another stateful application to operate.
- Visual workflows can hide complexity and become harder to review than code.
- n8n is suitable for orchestration and integration glue, not for core application logic.
- Workflow import/export and credential setup are not as clean as normal application CI/CD.

### Miscellaneous
- Treat n8n as a dev automation tool first. Re-evaluate before using it for production-critical workflows.
- Keep secrets out of workflow JSON; use External Secrets, environment variables, or n8n credentials.
