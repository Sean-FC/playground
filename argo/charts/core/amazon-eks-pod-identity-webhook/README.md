# Amazon EKS Pod Identity Webhook

Vendors templates created from [AWS EKS Pod Identity Webhook](from https://github.com/aws/eks-pod-identity-webhook).

## Updating

Fetch the upstream standard-install manifest, replace the existing template and bump the appVersion:
```bash
# If a major version bump is required, reclone + build the template; compare
VERSION="0.6.13"
git clone "https://github.com/aws/amazon-eks-pod-identity-webhook/" pod-irsa
cd pod-irsa && git checkout "v${VERSION}"
make prep-config > ../argo/charts/core/amazon-eks-pod-identity-webhook/updated.yaml
helm template -n irsa ../argo/charts/core/amazon-eks-pod-identity-webhook . > prior.yaml
# Reconcile the changes
diff updated.yaml prior.yaml
# Split the changes as appropriate, custom values have been made for simpler minor version updates
sed -i '' "s/^appVersion: \".*\"$/appVersion: \"${VERSION}\"/" \
  argo/charts/core/amazon-eks-pod-identity-webhook/Chart.yaml
```
