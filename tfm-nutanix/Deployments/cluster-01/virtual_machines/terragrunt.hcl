###############################################################################
# Terragrunt — cluster-01 / virtual_machines
#
# Deploys VMs defined in the parent virtual_machines.yaml using the
# virtual_machines Terraform module.
###############################################################################

include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

# ---------------------------------------------------------------------------
# Locals — load the cluster-specific VM YAML
# ---------------------------------------------------------------------------
locals {
  vm_config = yamldecode(file("${get_terragrunt_dir()}/../virtual_machines.yaml"))
}

# ---------------------------------------------------------------------------
# Terraform source — point to the virtual_machines module
# ---------------------------------------------------------------------------
terraform {
  source = "${get_repo_root()}/tfm-nutanix/Modules//virtual_machines/"
}

# ---------------------------------------------------------------------------
# Inputs — pass VM definitions to the module
# ---------------------------------------------------------------------------
inputs = merge(
  local.vm_config,
  {}
)
