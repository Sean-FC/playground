# n8n workflows

This folder stores importable n8n workflow JSON for the `argo/charts/data/n8n` deployment.

## Daily Kubernetes MCP health Slack digest

`daily-k8s-mcp-health-slack.workflow.json` runs once per day and sends a cluster health digest to Slack.

The workflow expects a Kubernetes MCP server reachable from the n8n pod. It uses n8n's built-in MCP Client node, so the deployed n8n version must include `@n8n/n8n-nodes-langchain.mcpClient`.

It defaults to the tool names exposed by the local Kubernetes MCP integration:

- `events_list`
- `pods_list`
- `resources_list`

The workflow calls `resources_list` for Deployments, Jobs, PVCs, Nodes, cert-manager Certificates, ExternalSecrets, and Argo CD Applications.

### Required configuration

The workflow defaults to this in-cluster MCP endpoint:

```text
http://k8s.mcps.svc.cluster.local:8080/mcp
```

If your service exposes MCP on another path or port, update the `endpointUrl` field on each `MCP ...` node, or let the chart import job interpolate it before import.

```text
http://k8s.mcps.svc.cluster.local:8080/mcp
```

Configure the `Send Slack digest` node after importing:

```text
https://hooks.slack.com/services/REPLACE/ME
```

Replace that placeholder with the target Slack incoming webhook URL, or let the chart import job interpolate it before import.

Digest tuning currently lives in the `Render digest` Code node:

```text
clusterName=dev
lookbackHours=24
restartWarningThreshold=5
maxItemsPerSection=25
maxEvents=50
```

After importing the workflow:

1. Configure the `Send Slack digest` webhook URL.
2. If the MCP endpoint requires authentication, configure credentials on each `MCP ...` node.
3. If your MCP server exposes different tool names, update the `MCP ...` nodes in the workflow editor.

### Import

From an n8n pod:

```bash
n8n import:workflow --input=/path/to/daily-k8s-mcp-health-slack.workflow.json
```

Leave the workflow inactive until the MCP endpoint and Slack webhook are configured.
