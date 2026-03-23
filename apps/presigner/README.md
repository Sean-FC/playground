# Presigner
This repository is intended to host a simple service used for generating presigned object storage links.

[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)
[![trivy](https://img.shields.io/badge/trivy-cve_scanning-yellow?logo=Aqua)](https://github.com/aquasecurity/trivy)

## Getting started
### Tooling
- [uv](https://docs.astral.sh/uv/): Dependency management + build tool
- [docker](https://docs.docker.com/get-docker/): Container technology

## Service
### Why
From the [docs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-presigned-url.html), there is an important limitation:
regardless of the expiry time requested by the client, the effective upper bound is also constrained by the lifetime of the
credentials that created the presigned URL.

This becomes awkward when presigned URLs are generated from workloads using temporary credentials, such as EKS/K3s workloads
using IRSA or automation running in CI.

A direct presigned URL is therefore a poor fit for long-lived references such as pull request comments. By the time a reviewer
clicks the link, the original URL may already have expired even though the underlying file still exists.

Instead, this toy service provides a stable application URL that can be placed in a PR comment, for example
`https://my-service/files/abc.txt`. When a user clicks that link, the service resolves the backing object, applies any required
authorization, and issues a fresh short-lived CloudFront signed URL for the download.

![presigned_limitation_illustration](./assets/presigned_limitation.png)
