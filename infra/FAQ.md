g# FAQ

### How do I handle secrets?
- SOPS essentially adds ciphertext to a file + metadata about the encryption key allowing one to decrypt the details if they have access to the specific key
- The bootstrap module creates a single KMS key
- The following one-liner can get the KMS key-arn + pipe it to SOPs to encrypt + edit your secrets in your default text editor

```bash
#!/usr/bin/env bash
export ACCOUNT='dev'
# One-liner
SOPS_KMS_ARN=$(aws kms list-keys --output json | jq -r ".Keys[] |select (.KeyId |contains(\"$(aws kms list-aliases --output json | jq -r '.Aliases[] |select (.AliasArn |contains(":alias/external")) | "\(.TargetKeyId)"')\")) | \"\(.KeyArn)\"") sops accounts/${ACCOUNT:-dev}/secrets.enc.yaml
```

### How do I perform local development?
- typically zsh based with aliases + aws-vault for sessions

```bash
#!/usr/bin/env bash
export CI_PROJECT_DIR=$(pwd)
export MODULE_DIR='aws'
export ACCOUNT='dev'

ln -snf ${CI_PROJECT_DIR}/env/${ACCOUNT}/root.hcl ${CI_PROJECT_DIR}/root.hcl
ln -snf ${CI_PROJECT_DIR}/env/${ACCOUNT}/secrets.enc.yaml ${CI_PROJECT_DIR}/${MODULE_DIR}/secrets.enc.yaml
```
