include "common" {
  path = find_in_parent_folders("terragrunt.common.hcl")
}

include "env" {
  path = find_in_parent_folders("root.hcl")
}

generate "extra_providers" {
  path      = "extra_providers.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "github" {
  owner = "Sean-FC"
  token = local.secrets_main.github.pat
}

EOF
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

variable "k3s_enabled" {
  type = bool
}

variable "k3s_version" {
  type = string
}

variable "k3s_server_instance_type" {
  type = string
}

variable "k3s_agent_count" {
  type = number
}

variable "k3s_agent_instance_type" {
  type = string
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

  k3s_enabled                       = true
  k3s_version                       = "v1.34.3+k3s1"
  k3s_server_instance_type          = "t4g.small"
  k3s_agent_count                   = 0
  k3s_agent_instance_type           = "t4g.small"
}
