###############################################################################
# Outputs
###############################################################################

# ---------------------------------------------------------------------------
# Lookup Maps (useful for debugging or external reference)
# ---------------------------------------------------------------------------

output "cluster_map" {
  description = "Map of cluster name → ext_id discovered from Prism Central."
  value       = local.cluster_map
}

output "subnet_map" {
  description = "Map of subnet name → ext_id discovered from Prism Central."
  value       = local.subnet_map
}

output "image_map" {
  description = "Map of image name → ext_id discovered from Prism Central."
  value       = local.image_map
}

output "storage_container_map" {
  description = "Map of storage container name → ext_id discovered from Prism Central."
  value       = local.storage_container_map
}

# ---------------------------------------------------------------------------
# Virtual Machines
# ---------------------------------------------------------------------------

output "virtual_machines" {
  description = "Map of all managed VMs keyed by name with key attributes."
  value = {
    for name, vm in nutanix_virtual_machine_v2.vm : name => {
      ext_id               = vm.id
      name                 = vm.name
      description          = vm.description
      power_state          = vm.power_state
      num_sockets          = vm.num_sockets
      num_cores_per_socket = vm.num_cores_per_socket
      memory_size_bytes    = vm.memory_size_bytes
      machine_type         = vm.machine_type
      cluster_ext_id       = vm.cluster[0].ext_id
    }
  }
}

output "vm_ids" {
  description = "Map of VM name → ext_id (UUID)."
  value = {
    for name, vm in nutanix_virtual_machine_v2.vm : name => vm.id
  }
}

output "vm_names" {
  description = "List of all managed VM names."
  value       = [for name, vm in nutanix_virtual_machine_v2.vm : vm.name]
}
