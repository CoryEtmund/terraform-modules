###############################################################################
# Networks (Subnets) Module — Locals
###############################################################################

locals {
  # Build a name → ext_id lookup map from all discovered subnets
  all_subnets = {
    for subnet in data.nutanix_subnets_v2.all.subnet_entities :
    subnet.name => subnet.ext_id
  }

  # If a filter list was provided, narrow down; otherwise return all
  subnets = length(var.subnets) > 0 ? {
    for name, id in local.all_subnets : name => id
    if contains(var.subnets, name)
  } : local.all_subnets
}
