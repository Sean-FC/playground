resource "aws_signer_signing_profile" "notation_oci" {
  name_prefix = module.context.stage
  platform_id = "Notation-OCI-SHA384-ECDSA"
  signature_validity_period {
    value = 2
    type  = "YEARS"
  }
  tags = module.context.tags
}
