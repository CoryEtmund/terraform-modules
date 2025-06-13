variable "virtual_machines" {
  description = "List of virtual machines to deploy"
  type = list(object({
    name                       = string
    description                = optional(string)
    power_state                = optional(string)
    boot_type                  = string
    gpu_list                   = optional(list(map(string)))
    guest_customization_cloud_init = optional(string)
    memory_size_mib            = number
    num_sockets                = number
    num_vcpus_per_socket       = number
    cluster                    = object({ ext_id = string })
    categories                 = optional(map(string))
    disk_list = list(object({
      data_source_reference = optional(object({
        kind = string
        uuid = string
      }))
      device_properties = optional(object({
        device_type = string
        disk_address = optional(object({
          adapter_type = string
          device_index = number
        }))
      }))
    }))
    nic_list = list(object({
      subnet_uuid = string
      ip_endpoint_list = optional(list(object({
        ip = string
      })))
    }))
  }))
}