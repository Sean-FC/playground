include "common" {
  path = find_in_parent_folders("terragrunt.common.hcl")
}

include "env" {
  path = find_in_parent_folders("root.hcl")
}

generate "extras" {
  path      = "extra_variables.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
variable "vpc_cidr_block" {
  type = string
}

variable "self_managed_cidr_block" {
  type = string
}

variable "enable_nat" {
  type = bool
}

variable "gateway_endpoints" {
  type = list(string)
}

variable "interface_endpoints" {
  type = list(string)
}

EOF
}

inputs = {
  project = "aws"

  vpc_cidr_block          = "10.10.0.0/18"
  self_managed_cidr_block = "10.10.0.0/19"
  enable_nat              = true

  gateway_endpoints     = ["s3", "dynamodb"]
  interface_endpoints   = [] # ["kms"]
}
