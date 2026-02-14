###############################################################################
# Declarative Import Blocks
#
# Subnets with `import_uuid` set are imported into Terraform state on the
# first apply.  Once imported, remove the import_uuid value (set to null)
# so subsequent plans do not attempt re-import.
#
# Requires Terraform >= 1.5.0
###############################################################################

import {
  for_each = local.subnets_to_import
  to       = nutanix_subnet_v2.subnet[each.key]
  id       = each.value.import_uuid
}
