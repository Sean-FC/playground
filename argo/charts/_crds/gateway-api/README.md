# Gateway API CRDs

Vendors upstream Gateway API CRDs for Argo management

## Updating

Fetch the upstream standard-install manifest, replace the existing template and bump the appVersion:
```bash
VERSION="1.5.1"
curl -fsSL \
  "https://github.com/kubernetes-sigs/gateway-api/releases/download/v${VERSION}/standard-install.yaml" \
  -o argo/charts/_crds/gateway-api/templates/standard-install.yaml
sed -i '' "s/^appVersion: \".*\"$/appVersion: \"${VERSION}\"/" \
  argo/charts/_crds/gateway-api/Chart.yaml
```
