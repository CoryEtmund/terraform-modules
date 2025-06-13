resource "nutanix_virtual_machine_v2" "vm" {
  for_each = local.vms

  name         = each.value.name
  description  = try(each.value.description, null)
  power_state  = try(each.value.power_state, null)
  boot_type    = each.value.boot_type

  cluster {
    ext_id = each.value.cluster.ext_id
  }

  memory_size_mib      = each.value.memory_size_mib
  num_sockets          = each.value.num_sockets
  num_vcpus_per_socket = each.value.num_vcpus_per_socket

  guest_customization_cloud_init = try(each.value.guest_customization_cloud_init, null)

  dynamic "disk_list" {
    for_each = each.value.disk_list
    content {
      data_source_reference = try(disk_list.value.data_source_reference, null)
      device_properties     = try(disk_list.value.device_properties, null)
    }
  }

  dynamic "nic_list" {
    for_each = each.value.nic_list
    content {
      subnet_uuid = nic_list.value.subnet_uuid
      ip_endpoint_list = try(nic_list.value.ip_endpoint_list, null)
    }
  }

  categories = try(each.value.categories, null)
  gpu_list   = try(each.value.gpu_list, null)
}