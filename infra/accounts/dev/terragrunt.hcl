# For local development, root.hcl is symlinked to env/dev/root.hcl by default
locals {
  aws_main_region   = "eu-west-1"
  state_bucket_name = "seanfc-personal-terraform"
}

remote_state {
  backend = "s3"
  config = {
    bucket       = local.state_bucket_name
    key          = "infra/${path_relative_to_include()}/terraform.tfstate"
    region       = local.aws_main_region
    encrypt      = true
    use_lockfile = true
  }
  generate = {
    path      = "tg_backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  stage             = "dev"
  aws_region        = local.aws_main_region
  state_bucket_name = local.state_bucket_name
}
