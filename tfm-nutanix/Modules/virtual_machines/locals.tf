###############################################################################
# Virtual Machine Locals
###############################################################################

locals {
  # Transform the list of VMs into a map keyed by name for use with for_each
  vms = { for vm in var.virtual_machines : vm.name => vm }

  # Separate VMs that need to be imported (have import_uuid set)
  vms_to_import = {
    for name, vm in local.vms : name => vm
    if vm.import_uuid != null
  }

  # VMs being created fresh (no import_uuid)
  vms_to_create = {
    for name, vm in local.vms : name => vm
    if vm.import_uuid == null
  }
}
