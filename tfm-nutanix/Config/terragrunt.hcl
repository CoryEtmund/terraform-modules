# ────────────────
# Config/terragrunt.hcl
# ────────────────

locals {
  virtual_machines_config = yamldecode(file(find_in_parent_folders("virtual_machines.yaml")))
  clusters_config         = yamldecode(file(find_in_parent_folders("clusters.yaml")))
  networks_config         = yamldecode(file(find_in_parent_folders("networks.yaml")))
}

# Include base configuration and define modules
terraform {
  source = "../Modules//${path_relative_to_include()}/"
}

inputs = merge(
  local.virtual_machines_config,
  local.clusters_config,
  local.networks_config,
)