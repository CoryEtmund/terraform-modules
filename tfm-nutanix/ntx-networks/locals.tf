###############################################################################
# Locals — Lookup Maps & Subnet Transforms
###############################################################################

locals {

  # ---------------------------------------------------------------------------
  # Name → ext_id lookup maps (built from data sources)
  #
  # IMPORTANT: Names must be unique within each resource type.  If duplicates
  # exist Terraform will raise an error.  In that case, consider filtering the
  # data sources or using unique names.
  # ---------------------------------------------------------------------------

  cluster_map = {
    for c in data.nutanix_clusters_v2.all.cluster_entities :
    c.name => c.ext_id
  }

  # ---------------------------------------------------------------------------
  # Subnet list → map keyed by name (for use with for_each)
  # ---------------------------------------------------------------------------

  subnets = { for s in var.subnets : s.name => s }

  # ---------------------------------------------------------------------------
  # Separate subnets that need to be imported (have import_uuid set)
  # ---------------------------------------------------------------------------

  subnets_to_import = {
    for name, s in local.subnets : name => s
    if s.import_uuid != null
  }
}
