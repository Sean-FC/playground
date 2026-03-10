include "common" {
  path = find_in_parent_folders("terragrunt.common.hcl")
}

include "env" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  project = "bootstrap"
}
