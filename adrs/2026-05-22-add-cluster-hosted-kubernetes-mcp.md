# Add Cluster-Hosted Kubernetes MCP

## Status
Accepted

## Context
Cluster debugging currently depends on each operator having a working local Kubernetes MCP server or falling back to direct `kubectl` access.

That local dependency is inconvenient for quick investigations and creates drift between operators, because local MCP versions, kubeconfig contexts, and available tools can differ.

We want a shared MCP endpoint for routine read-only inspection of the dev cluster, while avoiding any path for destructive Kubernetes operations.

## Options Considered
- Continue requiring local Kubernetes MCP servers
- Run a cluster-hosted Kubernetes MCP with read-only access
- Expose a broader cluster management MCP with write access

## Decision
Use a **cluster-hosted Kubernetes MCP** for the dev cluster.

The MCP runs from the `argo/charts/ml/mcps` umbrella chart and exposes a Gateway route at `k8s.mcp.dev.enervate.io`. It is configured for read-only use only: Kubernetes RBAC binds the service account to `view`, MCP `read_only` mode is enabled, destructive tools are disabled, and the exposed tool list is allowlisted.

## Consequences
### Positive
- Makes cluster debugging faster since there's a shared remote MCP endpoint.
- Avoids requiring a local Kubernetes MCP server for routine read-only inspection.
- Keeps tool behavior consistent across operators and automation.
- Reduces blast radius by combining Kubernetes RBAC with MCP-level read-only controls.

### Negative
- Adds another cluster service and route to operate.
