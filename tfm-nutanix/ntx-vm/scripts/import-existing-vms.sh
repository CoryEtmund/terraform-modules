#!/usr/bin/env bash
###############################################################################
# import-existing-vms.sh — CLI import helper (fallback method)
#
# The preferred approach is declarative import blocks (set import_uuid in
# terraform.tfvars and run `terraform apply`).  Use this script only if the
# declarative approach encounters issues.
#
# Usage:
#   ./scripts/import-existing-vms.sh [--dry-run]
#
# Run from the tfm-nutanix/ root directory.
###############################################################################

set -euo pipefail

DRY_RUN="${1:-}"
TFVARS_FILE="terraform.tfvars"

if [[ ! -f "$TFVARS_FILE" ]]; then
    echo "ERROR: Cannot find $TFVARS_FILE in current directory." >&2
    echo "Run this script from the tfm-nutanix/ root directory." >&2
    exit 1
fi

echo ""
echo "=== Nutanix VM Import Helper ==="
echo "Config: $TFVARS_FILE"
echo ""

# Extract name/import_uuid pairs from terraform.tfvars
count=0
vm_name=""

while IFS= read -r line; do
    # Match: name = "something"
    if [[ "$line" =~ name[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
        vm_name="${BASH_REMATCH[1]}"
    fi

    # Match: import_uuid = "something"
    if [[ "$line" =~ import_uuid[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
        import_uuid="${BASH_REMATCH[1]}"
        resource="nutanix_virtual_machine_v2.vm[\"${vm_name}\"]"

        echo "  VM Name : $vm_name"
        echo "  UUID    : $import_uuid"
        echo "  Address : $resource"

        if [[ "$DRY_RUN" == "--dry-run" ]]; then
            echo "  [DRY RUN] terraform import '$resource' '$import_uuid'"
        else
            echo "  Running import..."
            terraform import "$resource" "$import_uuid" || {
                echo "  WARNING: Import failed for $vm_name"
            }
            echo "  Done."
        fi
        echo ""
        count=$((count + 1))
    fi
done < "$TFVARS_FILE"

if [[ $count -eq 0 ]]; then
    echo "No VMs with import_uuid found. Nothing to import."
fi

echo "=== Import complete ($count VMs) ==="
echo ""
echo "Next steps:"
echo "  1. terraform plan        — verify no drift"
echo "  2. Adjust tfvars values if drift is detected"
echo "  3. Remove import_uuid from tfvars once plan is clean"
echo ""
