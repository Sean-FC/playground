include "common" {
  path = find_in_parent_folders("terragrunt.common.hcl")
}

include "env" {
  path = find_in_parent_folders("root.hcl")
}

generate "dependency" {
  path      = "dependencies.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
data "terraform_remote_state" "bootstrap" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = var.bootstrap_state_location
    region = var.aws_region
  }
}

data "terraform_remote_state" "aws" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = var.aws_state_location
    region = var.aws_region
  }
}

data "aws_iam_openid_connect_provider" "k3s" {
  arn = data.terraform_remote_state.aws.outputs.k3s_oidc_provider_arn
}

EOF
}

inputs = {
  project = "apps"
}
