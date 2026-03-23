## Overview
[Reloader](https://github.com/stakater/Reloader) is a Kubernetes controller that automatically triggers rollouts of workloads
(like Deployments, StatefulSets, and more) whenever referenced Secrets or ConfigMaps are updated.


### Getting Started
tldr;
Opt in by:
a) Updating the [values.yaml](./values.yaml) `namespaceSelector` to include your namespace

b) Adding this annotation to your deployments:
```yaml
annotations:
  reloader.stakater.com/auto: "true"
```
