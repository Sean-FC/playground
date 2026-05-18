# Playground

Monorepo demonstrating some personal styles + rudimentary capabilities.

```mermaid
flowchart TB
    repo["Git Repo<br/>playground"] --> argo["Argo CD<br/>argo-cd / image updater"]

    subgraph layers[" "]
        direction TB

        subgraph shared["Shared platform layer"]
            subgraph networking["Networking"]
                gateway["Gateway API"]
                traefik["Traefik"]
                cert["cert-manager"]
                auth["OAuth2 Proxy"]
                tailscale["Tailscale"]
            end

            subgraph cloud["Cloud vendor specific"]
                eso["External Secrets"]
                podid["EKS Pod Identity"]
                ebs["AWS EBS CSI"]
            end

            subgraph scaling["Scaling and scheduling"]
                karpenter["Karpenter"]
                keda["KEDA"]
                gpu["NVIDIA GPU Operator"]
                gha["GHA<br/>ARC controller / runner scale set"]
            end

            subgraph observability["Observability and operations"]
                monitor["Monitoring<br/>Prometheus / Grafana / Loki / Tempo / Fluent Bit"]
                reloader["Reloader"]
                renovate["Renovate"]
                goldilocks["Goldilocks"]
                trivy["Trivy"]
                crowdsec["CrowdSec"]
            end
        end

        subgraph workloads["Workload layer"]
            app["Apps<br/>presigner - FastAPI"]
            postgres["Data<br/>postgres"]
            spark["Data<br/>spark operator / history server"]
            ml["ML<br/>ray"]
        end
    end

    argo --> shared
    argo --> workloads

    users["Users / DNS / HTTPS"] --> traefik
```

- [``apps/``](./cdk-clusters/) - Application code

- [``argo/``](./argo/) - Charts and manifests

- [``data/``](./data/) - Local exploration + simple pipeline layout

- [``infra/``](./infra/) - IaC

## Getting started

### Tooling
- [pipx](https://github.com/pypa/pipx): Tool installer in isolated environments for python tools
- [sdkman](https://sdkman.io/): Tool installer in isolated environments for JVMs / misc SDKs
- [pre-commit](https://pre-commit.com): Git hooks allowing reviewers to avoid style comments + focus on the actual changes
  - [hadolint](https://github.com/hadolint/hadolint): Consistent linting for Dockerfiles; alternatively use `hadolint-binary` in pre-commit hooks
