# ArgoCD

## Overview
[ArgoCD](https://argo-cd.readthedocs.io/en/stable/) is our deployment management tool of choice + always the first chart deployed on the cluster.

It's been configured primarily with:
- single-replica control plane sized for a small cluster
- an `AppProject` named `core` for 'platform-level' applications and another named `apps` for general applications
- domain value has been configured, but a cluster ingress controller is not yet available
- image-updater has been configured, but similarly disabled till ecr integration in place

## Installation
```bash
# Fetch the pinned version of the chart:
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm dependency update
# Install:
helm upgrade --install argocd . \
  --namespace argo \
  --create-namespace
# Create an app pointing back to this repo, allowing self-management!
# Thereafter, use ArgoCD for all other installs!
```
Following this, github access is required to allow Argo to self-manage.

To achieve this there is a terraformed deploy key that can be manually applied as a secret:
```
apiVersion: v1
kind: Secret
metadata:
  name: playground-access
  namespace: argo
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: ssh://git@github.com/Sean-FC/playground.git
  enableLfs: "true"
  sshPrivateKey: |
    ...
```

Subsequently, an application is via manifest for argo + applied.  Argo will then reconcile itself, viola.
