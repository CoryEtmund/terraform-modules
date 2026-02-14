###############################################################################
# Virtual Machine Outputs
###############################################################################

output "virtual_machines" {
  description = "Map of all managed VMs keyed by name, exposing key attributes."
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
      nics                 = vm.nics
    }
  }
}

output "vm_ids" {
  description = "Map of VM name to ext_id (UUID)."
  value = {
    for name, vm in nutanix_virtual_machine_v2.vm : name => vm.id
  }
}

output "vm_names" {
  description = "List of all managed VM names."
  value       = [for name, vm in nutanix_virtual_machine_v2.vm : vm.name]
}
