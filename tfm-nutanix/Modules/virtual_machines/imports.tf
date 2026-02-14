###############################################################################
# Dynamic Import Blocks for Existing Virtual Machines
#
# Terraform >= 1.5 supports declarative `import` blocks.  Any VM in the
# virtual_machines variable that has `import_uuid` set will generate an import
# block so that `terragrunt apply` (or `terraform apply`) automatically imports
# the resource into state on the first run.
#
# After the initial import + apply, you can remove the import_uuid values from
# the YAML config — the VMs will remain in state and be managed normally.
###############################################################################

import {
  for_each = local.vms_to_import
  to       = nutanix_virtual_machine_v2.vm[each.key]
  id       = each.value.import_uuid
}
