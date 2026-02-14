###############################################################################
# Declarative Import Blocks for Existing Virtual Machines
#
# Any VM with `import_uuid` set will be imported into Terraform state on the
# first `terraform apply`.  After the import succeeds, remove the import_uuid
# from your tfvars — the VM stays in state and is managed normally.
#
# Requires Terraform >= 1.5.0
###############################################################################

import {
  for_each = local.vms_to_import
  to       = nutanix_virtual_machine_v2.vm[each.key]
  id       = each.value.import_uuid
}
