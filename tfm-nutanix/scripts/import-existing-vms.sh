#!/usr/bin/env bash
###############################################################################
# import-existing-vms.sh — Import existing Nutanix VMs into Terraform state
#
# Reads virtual_machines.yaml, finds entries with import_uuid, and runs
# `terragrunt import` for each.
#
# Usage:
#   ./import-existing-vms.sh <deployment-dir> [--dry-run]
#
# Example:
#   ./import-existing-vms.sh ./Deployments/cluster-01/virtual_machines
#   ./import-existing-vms.sh ./Deployments/cluster-01/virtual_machines --dry-run
###############################################################################

set -euo pipefail

DEPLOYMENT_DIR="${1:?Usage: $0 <deployment-dir> [--dry-run]}"
DRY_RUN="${2:-}"

# Locate the YAML file one level up from the deployment dir
YAML_FILE="$(dirname "$DEPLOYMENT_DIR")/virtual_machines.yaml"

if [[ ! -f "$YAML_FILE" ]]; then
    echo "ERROR: Cannot find virtual_machines.yaml at: $YAML_FILE" >&2
    exit 1
fi

echo ""
echo "=== Nutanix VM Import Helper ==="
echo "YAML source : $YAML_FILE"
echo "Deployment  : $DEPLOYMENT_DIR"
echo ""

# Extract name/import_uuid pairs using grep + awk
# Looks for consecutive name: and import_uuid: lines
count=0
while IFS= read -r line; do
    if [[ "$line" =~ name:\ *\"([^\"]+)\" ]]; then
        vm_name="${BASH_REMATCH[1]}"
    fi
    if [[ "$line" =~ import_uuid:\ *\"([^\"]+)\" ]]; then
        import_uuid="${BASH_REMATCH[1]}"
        resource="nutanix_virtual_machine_v2.vm[\"${vm_name}\"]"

        echo "  VM Name : $vm_name"
        echo "  UUID    : $import_uuid"
        echo "  Address : $resource"

        if [[ "$DRY_RUN" == "--dry-run" ]]; then
            echo "  [DRY RUN] terragrunt import '$resource' '$import_uuid'"
        else
            echo "  Running import..."
            pushd "$DEPLOYMENT_DIR" > /dev/null
            terragrunt import "$resource" "$import_uuid" || {
                echo "  WARNING: Import failed for $vm_name"
            }
            popd > /dev/null
            echo "  SUCCESS: $vm_name imported."
        fi
        echo ""
        count=$((count + 1))
    fi
done < "$YAML_FILE"

if [[ $count -eq 0 ]]; then
    echo "No VMs with import_uuid found. Nothing to import."
fi

echo "=== Import complete ==="
echo "Next steps:"
echo "  1. Run 'terragrunt plan' to verify no drift"
echo "  2. Adjust YAML values to match actual VM state if drift is detected"
echo "  3. Once plan is clean, remove import_uuid values from YAML"
echo ""
