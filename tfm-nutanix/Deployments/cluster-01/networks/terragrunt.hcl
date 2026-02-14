###############################################################################
# Terragrunt — cluster-01 / networks (data lookup)
#
# Fetches subnet name → ext_id mappings from Prism Central.
###############################################################################

include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "${get_repo_root()}/tfm-nutanix/Modules//networks/"
}

inputs = {}
