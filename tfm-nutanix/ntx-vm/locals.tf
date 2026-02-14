###############################################################################
# Locals — Lookup Maps & VM Transforms
###############################################################################

locals {

  # ---------------------------------------------------------------------------
  # Name → ext_id lookup maps (built from data sources)
  #
  # IMPORTANT: Names must be unique within each resource type.  If duplicates
  # exist (e.g., two subnets with the same name in different clusters),
  # Terraform will raise an error.  In that case, consider filtering the data
  # sources or using unique names.
  # ---------------------------------------------------------------------------

  cluster_map = {
    for c in data.nutanix_clusters_v2.all.cluster_entities :
    c.name => c.ext_id
  }

  subnet_map = {
    for s in data.nutanix_subnets_v2.all.subnet_entities :
    s.name => s.ext_id
  }

  image_map = {
    for i in data.nutanix_images_v2.all.image_entities :
    i.name => i.ext_id
  }

  storage_container_map = {
    for sc in data.nutanix_storage_containers_v2.all.storage_containers :
    sc.name => sc.ext_id
  }

  # ---------------------------------------------------------------------------
  # VM list → map keyed by name (for use with for_each)
  # ---------------------------------------------------------------------------

  vms = { for vm in var.virtual_machines : vm.name => vm }

  # ---------------------------------------------------------------------------
  # Separate VMs that need to be imported (have import_uuid set)
  # ---------------------------------------------------------------------------

  vms_to_import = {
    for name, vm in local.vms : name => vm
    if vm.import_uuid != null
  }
}
