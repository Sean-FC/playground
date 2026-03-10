terraform_version_constraint  = ">= 1.14.6"
terragrunt_version_constraint = ">= 0.99.1"

generate "context" {
  path = "context.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
# For consistent naming across resources
module "context" {
  source    = "git::https://github.com/cloudposse/terraform-null-label?ref=tags/0.25.0"
  enabled   = true
  namespace = var.namespace
  stage     = var.stage
  name      = var.project
  delimiter = "-"
}
EOF
}

generate "data" {
  path = "data.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
  region = var.aws_region
}

data "aws_availability_zones" "current" {
  filter {
    name   = "group-name"
    values = [data.aws_region.current.region]
  }
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# .id gives the alias, not the actual id/arn
data "aws_ebs_default_kms_key" "current" {
}

data "aws_kms_alias" "default_ebs" {
  name = data.aws_ebs_default_kms_key.current.key_arn
}

# Managed keys
data "aws_kms_alias" "ssm" {
  name = "alias/aws/ssm"
}

locals {
  is_dev = module.context.stage == "dev"
}

EOF
}

generate "sops" {
  path = "sops.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
locals {
  is_bootstrap = var.project == "bootstrap"
  secrets_main = local.is_bootstrap ? null : yamldecode(data.sops_file.main[0].raw)
}

data "sops_file" "main" {
  count = local.is_bootstrap ? 0 : 1
  source_file = "./secrets.enc.yaml"
  input_type  = "yaml"
}

EOF
}

generate "variables" {
  path = "variables.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
variable "namespace" {
  type = string
}

variable "stage" {
  type = string
}

variable "project" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "aws_region" {
  type = string
}

variable "state_bucket_name" {
  type = string
}

variable "bootstrap_state_location" {
  type = string
}

variable "aws_state_location" {
  type = string
}

EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.35.1"
    }
    databricks = {
      source = "databricks/databricks"
      version = "~> 1.29.0"
    }
    gitlab = {
      source = "gitlabhq/gitlab"
      version = "~> 18.9.0"
    }
    github = {
      source = "integrations/github"
      version = "~> 6.11.1"
    }
    sops = {
      source = "carlpett/sops"
      version = "~> 1.4.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 4.2.1"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  default_tags {
   tags = {
     CreatedBy = "Terraform"
     Env = title(var.stage)
   }
 }
}

provider "sops" {
}

EOF
}

inputs = {
  namespace                = "seanfc"
  bootstrap_state_location = "infra/bootstrap/terraform.tfstate"
  aws_state_location       = "infra/aws/terraform.tfstate"
}
